//
//  GameProgressStore.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import CoreGraphics
import Foundation
import Observation

@Observable
final class GameProgressStore {
    private static let saveKey = "moonBeastGameProgress"
    private static let defaultProfileIconImageName = "widerwillen_logo"
    private static let oldDefaultProfileIconImageName = "sprite_cookieman"
    private static let defaultCharacterID = "nimbi"
    private static let defaultCharacterSkinID = "nimbi_default"
    private static let defaultHeroAnimationID = "sprite_nimbi"
    private static let defaultHeroBasePower = 6
    private static let characterConfiguration =
        (try? CharacterConfiguration.load())
        ?? CharacterConfiguration(characters: [])
    private static let companionConfiguration =
        (try? CompanionConfiguration.load())
        ?? CompanionConfiguration(companions: [])
    private static let passConfiguration =
        (try? PassConfiguration.load()) ?? PassConfiguration(passes: [])
    private static let skillConfiguration =
        (try? SkillConfiguration.load()) ?? SkillConfiguration(skills: [])

    private(set) var stage = 0
    private(set) var stageHP = 12
    private(set) var maxStageHP = 12
    private(set) var accountLevel = 1
    private(set) var accountXP = 0
    private(set) var accountXPToNextLevel = 100
    private(set) var prestigeCount = 0
    private(set) var artifactShards = 0
    private(set) var skillBooks = 0
    private(set) var coins = 0
    private(set) var crystals = 0
    private(set) var pendingCoins = 0
    private(set) var pendingCrystals = 0
    private(set) var ownedSprites: [Int: OwnedSprite] = [:]
    private(set) var ownedCharacters: [String: OwnedCharacter] = [:]
    private(set) var unlockedCharacterSkinIDs: Set<String> = []
    private(set) var ownedArtifacts: [String: OwnedArtifact] = [:]
    private(set) var ownedItems: [String: OwnedItem] = [:]
    private(set) var lastSummonResults: [SummonResult] = []
    private(set) var lastArtifactSummonResults: [ArtifactSummonResult] = []
    private(set) var lastItemSummonResults: [ItemSummonResult] = []
    private(set) var ownedSkillLevels: [String: Int] = [:]
    private(set) var passPointsByID: [String: Int] = [:]
    private(set) var claimedPassRewardIDs: Set<String> = []
    private(set) var premiumPassIDs: Set<String> = []
    private(set) var purchasedShopProductIDs: Set<String> = []
    private(set) var tradeOfferPurchaseCounts: [String: Int] = [:]
    private(set) var eventCurrencies: [String: Int] = [:]
    private(set) var eventRunsByID: [String: EventRunProgress] = [:]
    private(set) var claimedGiftIDs: Set<String> = []
    private(set) var lastDailyLoginClaimDay = ""
    private(set) var lastDailyLoginClaimDaysByID: [String: String] = [:]
    private(set) var selectedProfileIconImageName =
        GameProgressStore.defaultProfileIconImageName
    private(set) var selectedCharacterID = GameProgressStore.defaultCharacterID
    private(set) var selectedCharacterSkinID =
        GameProgressStore.defaultCharacterSkinID
    private var lastIdleRewardUpdate = Date()

    init() {
        loadProgress()
        removeOldStarterCompanionIfNeeded()
        unlockDefaultCharacterIfNeeded()
        normalizeSelectedCharacterIfNeeded()
        normalizeProfileIconSelectionIfNeeded()
        recalculateStageHPIfNeeded()
        refreshIdleRewards()
    }

    func resetGameProgress() {
        let preservedPremiumPassIDs = premiumPassIDs
        let preservedPurchasedShopProductIDs = purchasedShopProductIDs

        UserDefaults.standard.removeObject(forKey: Self.saveKey)

        stage = 0
        stageHP = 12
        maxStageHP = 12
        accountLevel = 1
        accountXP = 0
        accountXPToNextLevel = Self.xpToNextLevel(for: accountLevel)
        prestigeCount = 0
        artifactShards = 0
        skillBooks = 0
        coins = 0
        crystals = 0
        pendingCoins = 0
        pendingCrystals = 0
        ownedSprites = [:]
        ownedCharacters = [:]
        unlockedCharacterSkinIDs = []
        ownedArtifacts = [:]
        ownedItems = [:]
        lastSummonResults = []
        lastArtifactSummonResults = []
        lastItemSummonResults = []
        ownedSkillLevels = [:]
        passPointsByID = [:]
        claimedPassRewardIDs = []
        premiumPassIDs = preservedPremiumPassIDs
        purchasedShopProductIDs = preservedPurchasedShopProductIDs
        tradeOfferPurchaseCounts = [:]
        eventCurrencies = [:]
        eventRunsByID = [:]
        claimedGiftIDs = []
        lastDailyLoginClaimDay = ""
        lastDailyLoginClaimDaysByID = [:]
        selectedProfileIconImageName = Self.defaultProfileIconImageName
        selectedCharacterID = Self.defaultCharacterID
        selectedCharacterSkinID = Self.defaultCharacterSkinID
        lastIdleRewardUpdate = Date()

        unlockDefaultCharacterIfNeeded()
        normalizeSelectedCharacterIfNeeded()
        normalizeProfileIconSelectionIfNeeded()
        recalculateStageHPIfNeeded()
        saveProgress()
    }

    var unlockedSpriteIndices: Set<Int> {
        Set(ownedSprites.keys)
    }

    var battleSpriteIndices: Set<Int> {
        unlockedSpriteIndices
    }

    var battleHeroAnimationID: String {
        selectedCharacterSkin?.animationID ?? Self.defaultHeroAnimationID
    }

    var battleCompanionAnimationIDs: Set<String> {
        Set(
            ownedSprites.keys.compactMap {
                Self.companionConfiguration.companion(spriteIndex: $0)?
                    .animationID
            }
        )
    }

    var hasCompanionSprites: Bool {
        !ownedSprites.isEmpty
    }

    var selectedCharacter: CharacterDefinition? {
        Self.characterConfiguration.character(id: selectedCharacterID)
            ?? Self.characterConfiguration.defaultCharacter
    }

    var selectedCharacterSkin: CharacterSkin? {
        Self.characterConfiguration.skin(
            id: selectedCharacterSkinID,
            for: selectedCharacterID
        ) ?? Self.characterConfiguration.defaultSkin(for: selectedCharacterID)
    }

    var ownedCharacterList: [OwnedCharacter] {
        Array(ownedCharacters.values)
    }

    var characterDefinitions: [CharacterDefinition] {
        Self.characterConfiguration.characters
    }

    func isSelectedCharacter(_ characterID: String) -> Bool {
        selectedCharacterID == characterID
    }

    func selectCharacter(_ character: CharacterDefinition) {
        guard ownedCharacters[character.id] != nil else { return }

        selectedCharacterID = character.id
        selectedCharacterSkinID =
            Self.characterConfiguration.defaultSkin(for: character.id)?.id
            ?? character.defaultSkinID
        saveProgress()
    }

    func isSkinUnlocked(_ skin: CharacterSkin) -> Bool {
        unlockedCharacterSkinIDs.contains(skin.id)
    }

    func isSelectedSkin(_ skin: CharacterSkin) -> Bool {
        selectedCharacterSkinID == skin.id
    }

    func selectSkin(_ skin: CharacterSkin, for character: CharacterDefinition) {
        guard ownedCharacters[character.id] != nil,
            isSkinUnlocked(skin)
        else {
            return
        }

        selectedCharacterID = character.id
        selectedCharacterSkinID = skin.id
        saveProgress()
    }

    var battlePower: Int {
        manualAttackPower + companionAttackPower
    }

    private var manualAttackPower: Int {
        let heroPower =
            if let character = selectedCharacter,
                let ownedCharacter = ownedCharacters[character.id]
            {
                Self.scaledPower(
                    base: character.baseTapDamage,
                    level: ownedCharacter.stars
                )
            } else {
                Self.defaultHeroBasePower
            }
        let artifactPower = ownedArtifacts.values.reduce(0) {
            $0 + Self.scaledPower(base: $1.damageBonus, level: $1.level)
        }
        let itemPower = ownedItems.values.reduce(0) {
            $0 + Self.scaledPower(base: $1.damageBonus, level: $1.level)
        }
        let accountPower = max(accountLevel - 1, 0) * 2
        let prestigePower = prestigeCount * 4
        let rawPower =
            heroPower + artifactPower + itemPower
            + accountPower + prestigePower
        return max(
            1,
            Int(
                (Double(rawPower) * (1.0 + skillBonus(for: .damage)))
                    .rounded()
            )
        )
    }

    private var companionAttackPower: Int {
        ownedSprites.values
            .reduce(0) {
                let basePower =
                    Self.companionConfiguration.companion(
                        spriteIndex: $1.spriteIndex
                    )?.baseDPS ?? Self.rarityPower($1.rarity)
                return $0
                    + Self.scaledPower(
                        base: basePower,
                        level: $1.stars
                    )
            }
    }

    var tapDamage: Int {
        let multiplier = 0.45 + skillBonus(for: .tapDamage)
        return max(1, Int((Double(manualAttackPower) * multiplier).rounded()))
    }

    var spriteDamage: Int {
        guard companionAttackPower > 0 else { return 0 }

        let multiplier = 1.0 + skillBonus(for: .spriteDamage)
        let prestigeMultiplier = 1.0 + Double(prestigeCount) * 0.12
        return max(
            1,
            Int(
                (Double(companionAttackPower) * multiplier * prestigeMultiplier)
                    .rounded()
            )
        )
    }

    var spriteAttackInterval: Duration {
        let speedBonus = min(skillBonus(for: .attackSpeed), 0.65)
        let seconds = max(0.45, 1.45 * (1.0 - speedBonus))
        return .milliseconds(Int(seconds * 1000))
    }

    var activeBattleSkills: [BattleActiveSkill] {
        Self.skillConfiguration.skills.compactMap { skill in
            guard
                let activation = skill.activation,
                skillLevel(for: skill) > 0
            else {
                return nil
            }

            let level = skillLevel(for: skill)
            let damageMultiplier =
                activation.damageMultiplier
                * (1.0 + Double(max(level - 1, 0)) * skill.valuePerLevel)
            let damage = max(
                1,
                Int((Double(manualAttackPower) * damageMultiplier).rounded())
            )

            return BattleActiveSkill(
                id: skill.id,
                title: skill.title,
                imageName: skill.imageName,
                kind: activation.kind,
                durationSeconds: activation.durationSeconds
                    * (1.0 + skillBonus(for: .activeSkillDuration)),
                cooldownSeconds: activation.cooldownSeconds
                    * (1.0 - min(skillBonus(for: .activeSkillCooldown), 0.7)),
                tickIntervalSeconds: activation.intervalSeconds,
                damage: damage,
                companionAnimationID: activation.companionAnimationID
            )
        }
    }

    var hasPendingRewards: Bool {
        pendingCoins > 0 || pendingCrystals > 0
    }

    var idleCoinsPerMinute: Int {
        max(5, accountLevel * 4 + stage * 2 + battlePower)
    }

    var idleCrystalsPerHour: Int {
        max(1, accountLevel / 3 + prestigeCount)
    }

    var stageHPProgress: CGFloat {
        CGFloat(stageHP) / CGFloat(max(maxStageHP, 1))
    }

    var accountXPProgress: CGFloat {
        CGFloat(accountXP) / CGFloat(max(accountXPToNextLevel, 1))
    }

    var canPrestige: Bool {
        stage >= 20
    }

    @discardableResult
    func attackStage(damage: Int? = nil) -> BattleAttackResult {
        let damageValue = max(damage ?? tapDamage, 1)
        let damageDealt = min(stageHP, damageValue)
        stageHP = max(stageHP - damageValue, 0)

        if stageHP == 0 {
            let rewards = advanceStage()
            return BattleAttackResult(
                damageDealt: damageDealt,
                coinsAwarded: rewards.coins,
                crystalsAwarded: rewards.crystals,
                skillBooksAwarded: rewards.skillBooks
            )
        } else {
            saveProgress()
            return BattleAttackResult(damageDealt: damageDealt)
        }
    }

    private func advanceStage() -> StageRewards {
        let nextStage = stage + 1
        let skippedStages = rollStageSkipCount(from: nextStage)
        let reachedStage = nextStage + skippedStages
        let earnedCoins = Int(
            (Double(25 + reachedStage * 3)
                * (1.0 + skillBonus(for: .coinDrop))
                * (1.0 + Double(skippedStages) * 0.65)).rounded()
        )
        let bossStagesCleared = (nextStage...reachedStage)
            .filter { $0.isMultiple(of: 10) }
            .count
        let earnedCrystals =
            bossStagesCleared > 0
            ? bossStagesCleared + reachedStage / 50
            : 0
        let earnedSkillBooks = rollSkillBookDrop(for: reachedStage)

        stage = reachedStage
        coins += earnedCoins
        skillBooks += earnedSkillBooks
        addAccountXP(12 + reachedStage * 2 + skippedStages * 5)
        maxStageHP = Self.maxHP(for: reachedStage, accountLevel: accountLevel)
        stageHP = maxStageHP

        crystals += earnedCrystals
        addPassPoints((bossStagesCleared > 0 ? 30 : 10) + skippedStages * 10)

        saveProgress()
        return StageRewards(
            coins: earnedCoins,
            crystals: earnedCrystals,
            skillBooks: earnedSkillBooks
        )
    }

    private func rollStageSkipCount(from nextStage: Int) -> Int {
        let chance = min(skillBonus(for: .stageSkipChance), 0.35)
        guard chance > 0, Double.random(in: 0..<1) < chance else {
            return 0
        }

        let skippedStage = nextStage + 1
        return skippedStage.isMultiple(of: 10) ? 0 : 1
    }

    func remainingRuns(for event: GameEvent) -> Int {
        let usedRuns = eventRunsByID[event.id]?.usedRuns ?? 0
        let resetDay = eventRunsByID[event.id]?.resetDay

        guard resetDay == Self.todayKey() else {
            return event.dailyLimit
        }

        return max(event.dailyLimit - usedRuns, 0)
    }

    func refreshDailyEventLimits(for events: [GameEvent]) {
        for event in events {
            resetEventIfNeeded(eventID: event.id)
        }
    }

    func eventMaxHP(for event: GameEvent) -> Int {
        let levelMultiplier = pow(1.12, Double(max(accountLevel - 1, 0)))
        return max(
            event.hp,
            Int((Double(event.hp) * levelMultiplier).rounded())
        )
    }

    @discardableResult
    func fightEvent(_ event: GameEvent) -> Bool {
        resetEventIfNeeded(eventID: event.id)

        guard remainingRuns(for: event) > 0 else { return false }

        let currentRun =
            eventRunsByID[event.id]
            ?? EventRunProgress(
                eventID: event.id,
                usedRuns: 0,
                resetDay: Self.todayKey()
            )

        eventRunsByID[event.id] = EventRunProgress(
            eventID: event.id,
            usedRuns: currentRun.usedRuns + 1,
            resetDay: Self.todayKey()
        )
        eventCurrencies[event.currencyStorageID, default: 0] +=
            event.rewards.chipAmount
        coins += event.rewards.coins
        crystals += event.rewards.crystals
        artifactShards += event.rewards.relics
        addPassPoints(14)
        saveProgress()
        return true
    }

    func claimRewards() {
        claimIdleRewards()
    }

    func selectProfileIcon(_ icon: ProfileIcon) {
        selectedProfileIconImageName = icon.imageName
        saveProgress()
    }

    func refreshIdleRewards(now: Date = Date()) {
        let elapsedSeconds = max(0, now.timeIntervalSince(lastIdleRewardUpdate))
        guard elapsedSeconds >= 60 else { return }

        let wholeMinutes = Int(elapsedSeconds / 60)
        let earnedCoins = wholeMinutes * idleCoinsPerMinute
        let earnedCrystals = wholeMinutes * idleCrystalsPerHour / 60

        pendingCoins += earnedCoins
        pendingCrystals += earnedCrystals
        lastIdleRewardUpdate.addTimeInterval(TimeInterval(wholeMinutes * 60))
        saveProgress()
    }

    func claimIdleRewards() {
        refreshIdleRewards()
        coins += pendingCoins
        crystals += pendingCrystals
        pendingCoins = 0
        pendingCrystals = 0
        saveProgress()
    }

    func canClaimGift(_ gift: GiftReward) -> Bool {
        !claimedGiftIDs.contains(gift.id)
    }

    @discardableResult
    func claimGift(_ gift: GiftReward) -> Bool {
        guard canClaimGift(gift) else { return false }

        for reward in gift.rewards {
            change(reward, by: reward.amount)
        }

        claimedGiftIDs.insert(gift.id)
        saveProgress()
        return true
    }

    @discardableResult
    func claimGifts(_ gifts: [GiftReward]) -> Int {
        let availableGifts = gifts.filter { canClaimGift($0) }
        guard !availableGifts.isEmpty else { return 0 }

        for gift in availableGifts {
            for reward in gift.rewards {
                change(reward, by: reward.amount)
            }

            claimedGiftIDs.insert(gift.id)
        }

        saveProgress()
        return availableGifts.count
    }

    func currentDailyLoginReward(from rewards: [DailyLoginReward])
        -> DailyLoginReward?
    {
        guard !rewards.isEmpty else { return nil }

        let dayOfYear =
            Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % rewards.count
        return rewards.sorted { $0.day < $1.day }[index]
    }

    var canClaimDailyLogin: Bool {
        lastDailyLoginClaimDay != Self.todayKey()
    }

    func canClaimDailyLogin(for login: DailyLoginCampaign) -> Bool {
        lastDailyLoginClaimDaysByID[login.id] != Self.todayKey()
    }

    func hasClaimableDailyLogin(in configuration: DailyLoginConfiguration)
        -> Bool
    {
        configuration.logins.contains { canClaimDailyLogin(for: $0) }
    }

    @discardableResult
    func claimDailyLoginReward(_ reward: DailyLoginReward) -> Bool {
        guard canClaimDailyLogin else { return false }

        for amount in reward.rewards {
            change(amount, by: amount.amount)
        }

        lastDailyLoginClaimDay = Self.todayKey()
        saveProgress()
        return true
    }

    @discardableResult
    func claimDailyLoginReward(
        _ reward: DailyLoginReward,
        in login: DailyLoginCampaign
    ) -> Bool {
        guard canClaimDailyLogin(for: login) else { return false }

        for amount in reward.rewards {
            change(amount, by: amount.amount)
        }

        let today = Self.todayKey()
        lastDailyLoginClaimDaysByID[login.id] = today
        if login.id == "standard" {
            lastDailyLoginClaimDay = today
        }
        saveProgress()
        return true
    }

    func amount(for resource: TradeResource) -> Int {
        switch resource {
        case .coins:
            coins
        case .crystals:
            crystals
        case .relics:
            artifactShards
        case .skillBooks:
            skillBooks
        case .eventChip:
            0
        }
    }

    func passPoints(for pass: BattlePassDefinition) -> Int {
        passPointsByID[pass.id, default: 0]
    }

    func isPremiumPassUnlocked(_ pass: BattlePassDefinition) -> Bool {
        pass.productID == nil || premiumPassIDs.contains(pass.id)
    }

    func isPassRewardUnlocked(
        _ reward: BattlePassReward,
        in pass: BattlePassDefinition
    ) -> Bool {
        passPoints(for: pass) >= reward.requiredPoints
            && (!reward.premium || isPremiumPassUnlocked(pass))
    }

    func isPassRewardClaimed(
        _ reward: BattlePassReward,
        in pass: BattlePassDefinition
    ) -> Bool {
        claimedPassRewardIDs.contains(passRewardKey(reward, in: pass))
    }

    func canClaimPassReward(
        _ reward: BattlePassReward,
        in pass: BattlePassDefinition
    ) -> Bool {
        isPassRewardUnlocked(reward, in: pass)
            && !isPassRewardClaimed(reward, in: pass)
    }

    @discardableResult
    func claimPassReward(
        _ reward: BattlePassReward,
        in pass: BattlePassDefinition
    ) -> Bool {
        guard canClaimPassReward(reward, in: pass) else { return false }

        for amount in reward.rewards {
            change(amount.resource, by: amount.amount)
        }

        claimedPassRewardIDs.insert(passRewardKey(reward, in: pass))
        saveProgress()
        return true
    }

    func unlockPremiumPass(_ pass: BattlePassDefinition) {
        premiumPassIDs.insert(pass.id)
        saveProgress()
    }

    func addPurchasedCrystals(_ amount: Int) {
        crystals += max(amount, 0)
        saveProgress()
    }

    func unlockPurchasedCharacterPack(_ pack: CharacterPack) {
        for characterID in pack.characterIDs {
            unlockCharacter(characterID)
        }

        for skinID in pack.skinIDs {
            unlockSkin(skinID)
        }

        for reward in pack.rewards {
            change(reward.resource, by: reward.amount)
        }

        if pack.bonusCrystals > 0 {
            crystals += pack.bonusCrystals
        }

        if pack.purchaseType == .nonConsumable {
            purchasedShopProductIDs.insert(pack.productID)
        }

        normalizeSelectedCharacterIfNeeded()
        saveProgress()
    }

    func isPurchasedShopProduct(_ productID: String) -> Bool {
        purchasedShopProductIDs.contains(productID)
    }

    func canApplyTradeOffer(_ offer: TradeOffer) -> Bool {
        if let limit = offer.limit,
            tradeOfferPurchaseCounts[offer.id, default: 0] >= limit
        {
            return false
        }

        return offer.costs.allSatisfy { amount(for: $0) >= $0.amount }
    }

    @discardableResult
    func applyTradeOffer(_ offer: TradeOffer) -> Bool {
        guard canApplyTradeOffer(offer) else { return false }

        for cost in offer.costs {
            change(cost, by: -cost.amount)
        }

        for reward in offer.rewards {
            change(reward, by: reward.amount)
        }

        for unlock in offer.unlocks {
            applyTradeUnlock(unlock)
        }

        tradeOfferPurchaseCounts[offer.id, default: 0] += 1
        saveProgress()
        return true
    }

    func prestige() {
        guard canPrestige else { return }

        let earnedShards = max(
            1,
            Int(
                (Double(stage / 10)
                    * (1.0 + skillBonus(for: .prestigeRelics))).rounded()
            )
        )
        prestigeCount += 1
        artifactShards += earnedShards
        stage = 1
        maxStageHP = Self.maxHP(for: stage, accountLevel: accountLevel)
        stageHP = maxStageHP
        saveProgress()
    }

    func skillLevel(for skill: SkillNode) -> Int {
        ownedSkillLevels[skill.id, default: 0]
    }

    func canUpgradeSkill(_ skill: SkillNode) -> Bool {
        return skillLevel(for: skill) < skill.maxLevel
            && skillBooks >= skill.cost
    }

    @discardableResult
    func upgradeSkill(_ skill: SkillNode) -> Bool {
        guard canUpgradeSkill(skill) else { return false }

        skillBooks -= skill.cost
        ownedSkillLevels[skill.id, default: 0] += 1
        saveProgress()
        return true
    }

    @discardableResult
    func summonSingle(from banner: SummonBanner) -> Bool {
        summon(count: 1, cost: banner.singleCost, from: banner)
    }

    @discardableResult
    func summonMulti(from banner: SummonBanner) -> Bool {
        summon(count: banner.multiCount, cost: banner.multiCost, from: banner)
    }

    @discardableResult
    func summonArtifactSingle(from banner: ArtifactBanner) -> Bool {
        summonArtifact(count: 1, cost: banner.singleCost, from: banner)
    }

    @discardableResult
    func summonArtifactMulti(from banner: ArtifactBanner) -> Bool {
        summonArtifact(
            count: banner.multiCount,
            cost: banner.multiCost,
            from: banner
        )
    }

    private func summon(count: Int, cost: Int, from banner: SummonBanner)
        -> Bool
    {
        guard canPay(cost: cost, for: banner.kind), count > 0 else {
            return false
        }

        pay(cost: cost, for: banner.kind)
        clearLastSummonResults()

        let results: [SummonResult] = (0..<count).compactMap { _ in
            guard let entry = rollEntry(from: banner.entries) else {
                return nil
            }

            return storeSummon(entry, kind: banner.kind)
        }

        lastSummonResults = results

        saveProgress()
        return !lastSummonResults.isEmpty
    }

    private func rollEntry(from entries: [SummonEntry]) -> SummonEntry? {
        let totalWeight = entries.reduce(0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else { return entries.randomElement() }

        var roll = Double.random(in: 0..<totalWeight)

        for entry in entries {
            roll -= max(entry.weight, 0)

            if roll <= 0 {
                return entry
            }
        }

        return entries.last
    }

    private func summonArtifact(
        count: Int,
        cost: Int,
        from banner: ArtifactBanner
    ) -> Bool {
        guard artifactShards >= cost, count > 0 else { return false }

        artifactShards -= cost
        clearLastSummonResults()
        lastArtifactSummonResults = (0..<count).compactMap { _ in
            guard let entry = rollArtifact(from: banner.entries) else {
                return nil
            }

            let oldLevel = ownedArtifacts[entry.id]?.level ?? 0
            let newLevel = oldLevel + 1
            ownedArtifacts[entry.id] = OwnedArtifact(
                artifactID: entry.id,
                name: entry.name,
                imageName: entry.imageName,
                rarity: entry.rarity,
                damageBonus: entry.damageBonus,
                level: newLevel
            )

            return ArtifactSummonResult(
                entry: entry,
                isDuplicate: oldLevel > 0,
                level: newLevel
            )
        }

        saveProgress()
        return !lastArtifactSummonResults.isEmpty
    }

    private func storeSummon(_ entry: SummonEntry, kind: SummonKind)
        -> SummonResult
    {
        switch kind {
        case .sprite:
            if let characterID = entry.characterID {
                let character =
                    Self.characterConfiguration.character(id: characterID)
                let oldStars = ownedCharacters[characterID]?.stars ?? 0
                let newStars = oldStars + 1
                let imageName =
                    character?.skins.first { $0.id == entry.skinID }?.imageName
                    ?? character?.skins.first?.imageName
                    ?? entry.imageName
                ownedCharacters[characterID] = OwnedCharacter(
                    characterID: characterID,
                    name: character?.name ?? entry.name,
                    imageName: imageName,
                    rarity: character?.rarity ?? entry.rarity,
                    stars: newStars
                )

                if let skinID = entry.skinID {
                    unlockedCharacterSkinIDs.insert(skinID)
                }

                return SummonResult(
                    entry: entry,
                    kind: kind,
                    isDuplicate: oldStars > 0,
                    level: newStars
                )
            }

            let spriteIndex = entry.spriteIndex ?? 0
            let companion =
                entry.companionID.flatMap {
                    Self.companionConfiguration.companion(id: $0)
                }
                ?? Self.companionConfiguration.companion(
                    spriteIndex: spriteIndex
                )
            let oldStars = ownedSprites[spriteIndex]?.stars ?? 0
            let newStars = oldStars + 1
            ownedSprites[spriteIndex] = OwnedSprite(
                spriteIndex: spriteIndex,
                name: companion?.name ?? entry.name,
                imageName: companion?.imageName ?? entry.imageName,
                rarity: companion?.rarity ?? entry.rarity,
                stars: newStars
            )
            return SummonResult(
                entry: entry,
                kind: kind,
                isDuplicate: oldStars > 0,
                level: newStars
            )
        case .relic:
            let oldLevel = ownedArtifacts[entry.id]?.level ?? 0
            let newLevel = oldLevel + 1
            ownedArtifacts[entry.id] = OwnedArtifact(
                artifactID: entry.id,
                name: entry.name,
                imageName: entry.imageName,
                rarity: entry.rarity,
                damageBonus: entry.damageBonus,
                level: newLevel
            )
            return SummonResult(
                entry: entry,
                kind: kind,
                isDuplicate: oldLevel > 0,
                level: newLevel
            )
        case .item:
            let oldLevel = ownedItems[entry.id]?.level ?? 0
            let newLevel = oldLevel + 1
            ownedItems[entry.id] = OwnedItem(
                itemID: entry.id,
                name: entry.name,
                imageName: entry.imageName,
                rarity: entry.rarity,
                damageBonus: entry.damageBonus,
                level: newLevel
            )
            return SummonResult(
                entry: entry,
                kind: kind,
                isDuplicate: oldLevel > 0,
                level: newLevel
            )
        }
    }

    private func canPay(cost: Int, for kind: SummonKind) -> Bool {
        switch kind {
        case .sprite, .item:
            crystals >= cost
        case .relic:
            artifactShards >= cost
        }
    }

    private func pay(cost: Int, for kind: SummonKind) {
        switch kind {
        case .sprite, .item:
            crystals -= cost
        case .relic:
            artifactShards -= cost
        }
    }

    private func change(_ resource: TradeResource, by amount: Int) {
        switch resource {
        case .coins:
            coins = max(coins + amount, 0)
        case .crystals:
            crystals = max(crystals + amount, 0)
        case .relics:
            artifactShards = max(artifactShards + amount, 0)
        case .skillBooks:
            skillBooks = max(skillBooks + amount, 0)
        case .eventChip:
            break
        }
    }

    private func amount(for amount: TradeResourceAmount) -> Int {
        switch amount.resource {
        case .eventChip:
            guard let eventID = amount.eventID else { return 0 }
            return eventCurrencies[eventID, default: 0]
        default:
            return self.amount(for: amount.resource)
        }
    }

    private func change(_ amount: TradeResourceAmount, by value: Int) {
        switch amount.resource {
        case .eventChip:
            guard let eventID = amount.eventID else { return }
            eventCurrencies[eventID] = max(
                eventCurrencies[eventID, default: 0] + value,
                0
            )
        default:
            change(amount.resource, by: value)
        }
    }

    private func applyTradeUnlock(_ unlock: TradeUnlockReward) {
        switch unlock.kind {
        case .character:
            if let characterID = unlock.characterID {
                unlockCharacter(characterID)
            }
        case .skin:
            if let skinID = unlock.skinID {
                unlockSkin(skinID)
            }
        case .item:
            let itemID = unlock.itemID ?? unlock.id
            let oldLevel = ownedItems[itemID]?.level ?? 0
            ownedItems[itemID] = OwnedItem(
                itemID: itemID,
                name: unlock.name,
                imageName: unlock.imageName,
                rarity: unlock.rarity ?? .rare,
                damageBonus: unlock.damageBonus ?? 1,
                level: oldLevel + 1
            )
        }
    }

    private func rollSkillBookDrop(for stage: Int) -> Int {
        let isBossStage = stage.isMultiple(of: 10)
        let baseChance = isBossStage ? 0.25 : 0.05
        let chance = min(baseChance + skillBonus(for: .dropChance), 0.65)
        guard Double.random(in: 0..<1) < chance else { return 0 }

        let bossBonus = isBossStage ? max(1, stage / 40) : 0
        return 1 + bossBonus
    }

    private func addPassPoints(_ amount: Int) {
        let points = max(amount, 0)
        guard points > 0 else { return }

        let passes =
            (try? PassConfiguration.load().passes)
            ?? Self.passConfiguration.passes

        for pass in passes {
            passPointsByID[pass.id, default: 0] += points
        }
    }

    private func unlockCharacter(_ characterID: String) {
        guard
            let character = Self.characterConfiguration.character(
                id: characterID
            )
        else { return }

        let currentStars = ownedCharacters[characterID]?.stars ?? 0
        let skin =
            Self.characterConfiguration.defaultSkin(for: characterID)
            ?? character.skins.first
        ownedCharacters[characterID] = OwnedCharacter(
            characterID: characterID,
            name: character.name,
            imageName: skin?.imageName ?? "icon_nimpi",
            rarity: character.rarity,
            stars: max(currentStars, 1)
        )
        unlockedCharacterSkinIDs.insert(character.defaultSkinID)
    }

    private func unlockSkin(_ skinID: String) {
        for character in Self.characterConfiguration.characters
        where character.skins.contains(where: { $0.id == skinID }) {
            unlockCharacter(character.id)
            unlockedCharacterSkinIDs.insert(skinID)
            return
        }
    }

    private func passRewardKey(
        _ reward: BattlePassReward,
        in pass: BattlePassDefinition
    ) -> String {
        "\(pass.id)::\(reward.id)"
    }

    private func clearLastSummonResults() {
        lastSummonResults = []
        lastArtifactSummonResults = []
        lastItemSummonResults = []
    }

    private func rollArtifact(from entries: [ArtifactEntry]) -> ArtifactEntry? {
        let totalWeight = entries.reduce(0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else { return entries.randomElement() }

        var roll = Double.random(in: 0..<totalWeight)

        for entry in entries {
            roll -= max(entry.weight, 0)

            if roll <= 0 {
                return entry
            }
        }

        return entries.last
    }

    private func addAccountXP(_ amount: Int) {
        accountXP += max(amount, 0)

        while accountXP >= accountXPToNextLevel {
            accountXP -= accountXPToNextLevel
            accountLevel += 1
            accountXPToNextLevel = Self.xpToNextLevel(for: accountLevel)
        }

        recalculateStageHPForAccountLevel()
    }

    private func loadProgress() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.saveKey),
            let snapshot = try? JSONDecoder().decode(
                ProgressSnapshot.self,
                from: data
            )
        else {
            return
        }

        stage = snapshot.stage
        stageHP = snapshot.stageHP
        maxStageHP = snapshot.maxStageHP
        accountLevel = snapshot.accountLevel
        accountXP = snapshot.accountXP
        accountXPToNextLevel = Self.xpToNextLevel(for: accountLevel)
        prestigeCount = snapshot.prestigeCount
        artifactShards = snapshot.artifactShards
        skillBooks = snapshot.skillBooks
        coins = snapshot.coins
        crystals = snapshot.crystals
        pendingCoins = snapshot.pendingCoins
        pendingCrystals = snapshot.pendingCrystals
        eventCurrencies = snapshot.eventCurrencies
        eventRunsByID = snapshot.eventRunsByID
        claimedGiftIDs = Set(snapshot.claimedGiftIDs)
        lastDailyLoginClaimDay = snapshot.lastDailyLoginClaimDay
        lastDailyLoginClaimDaysByID = snapshot.lastDailyLoginClaimDaysByID
        selectedProfileIconImageName = snapshot.selectedProfileIconImageName
        ownedSkillLevels = snapshot.ownedSkillLevels
        passPointsByID = snapshot.passPointsByID
        claimedPassRewardIDs = Set(snapshot.claimedPassRewardIDs)
        premiumPassIDs = Set(snapshot.premiumPassIDs)
        purchasedShopProductIDs = Set(snapshot.purchasedShopProductIDs)
        tradeOfferPurchaseCounts = snapshot.tradeOfferPurchaseCounts
        lastIdleRewardUpdate = Date(
            timeIntervalSince1970: snapshot.lastIdleRewardUpdate
        )
        ownedSprites = Dictionary(
            uniqueKeysWithValues: snapshot.ownedSprites.map {
                ($0.spriteIndex, $0)
            }
        )
        ownedCharacters = Dictionary(
            uniqueKeysWithValues: snapshot.ownedCharacters.map {
                ($0.characterID, $0)
            }
        )
        unlockedCharacterSkinIDs = Set(snapshot.unlockedCharacterSkinIDs)
        selectedCharacterID = snapshot.selectedCharacterID
        selectedCharacterSkinID = snapshot.selectedCharacterSkinID
        ownedArtifacts = Dictionary(
            uniqueKeysWithValues: snapshot.ownedArtifacts.map {
                ($0.artifactID, $0)
            }
        )
        ownedItems = Dictionary(
            uniqueKeysWithValues: snapshot.ownedItems.map {
                ($0.itemID, $0)
            }
        )
    }

    private func saveProgress() {
        let snapshot = ProgressSnapshot(
            stage: stage,
            stageHP: stageHP,
            maxStageHP: maxStageHP,
            accountLevel: accountLevel,
            accountXP: accountXP,
            prestigeCount: prestigeCount,
            artifactShards: artifactShards,
            skillBooks: skillBooks,
            coins: coins,
            crystals: crystals,
            pendingCoins: pendingCoins,
            pendingCrystals: pendingCrystals,
            ownedSprites: Array(ownedSprites.values),
            ownedCharacters: Array(ownedCharacters.values),
            unlockedCharacterSkinIDs: Array(unlockedCharacterSkinIDs),
            ownedArtifacts: Array(ownedArtifacts.values),
            ownedItems: Array(ownedItems.values),
            eventCurrencies: eventCurrencies,
            eventRunsByID: eventRunsByID,
            claimedGiftIDs: Array(claimedGiftIDs),
            lastDailyLoginClaimDay: lastDailyLoginClaimDay,
            lastDailyLoginClaimDaysByID: lastDailyLoginClaimDaysByID,
            selectedProfileIconImageName: selectedProfileIconImageName,
            selectedCharacterID: selectedCharacterID,
            selectedCharacterSkinID: selectedCharacterSkinID,
            ownedSkillLevels: ownedSkillLevels,
            passPointsByID: passPointsByID,
            claimedPassRewardIDs: Array(claimedPassRewardIDs),
            premiumPassIDs: Array(premiumPassIDs),
            purchasedShopProductIDs: Array(purchasedShopProductIDs),
            tradeOfferPurchaseCounts: tradeOfferPurchaseCounts,
            lastIdleRewardUpdate: lastIdleRewardUpdate.timeIntervalSince1970
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
    }

    private func removeOldStarterCompanionIfNeeded() {
        guard ownedSprites.count == 1,
            let starter = ownedSprites[0],
            starter.name == "Cookieman",
            starter.imageName == "sprite_cookieman",
            starter.stars == 1
        else {
            return
        }

        ownedSprites.removeValue(forKey: 0)
        saveProgress()
    }

    private func unlockDefaultCharacterIfNeeded() {
        guard ownedCharacters[Self.defaultCharacterID] == nil else { return }

        let character = Self.characterConfiguration.defaultCharacter
        ownedCharacters[character?.id ?? Self.defaultCharacterID] =
            OwnedCharacter(
                characterID: character?.id ?? Self.defaultCharacterID,
                name: character?.name ?? "Nimbi",
                imageName: character?.skins.first?.imageName ?? "icon_nimpi",
                rarity: character?.rarity ?? .legendary,
                stars: 1
            )
        unlockedCharacterSkinIDs.insert(
            character?.defaultSkinID ?? Self.defaultCharacterSkinID
        )
        saveProgress()
    }

    private func normalizeSelectedCharacterIfNeeded() {
        let fallbackCharacter =
            Self.characterConfiguration.defaultCharacter?.id
            ?? Self.defaultCharacterID
        let fallbackSkin =
            Self.characterConfiguration.defaultSkin(for: fallbackCharacter)?.id
            ?? Self.defaultCharacterSkinID

        if ownedCharacters[selectedCharacterID] == nil {
            selectedCharacterID = fallbackCharacter
        }

        if !unlockedCharacterSkinIDs.contains(selectedCharacterSkinID)
            || Self.characterConfiguration.skin(
                id: selectedCharacterSkinID,
                for: selectedCharacterID
            ) == nil
        {
            selectedCharacterSkinID = fallbackSkin
        }

        saveProgress()
    }

    private func normalizeProfileIconSelectionIfNeeded() {
        let availableIcons =
            (try? ProfileIconConfiguration.load().icons) ?? []
        let availableIconNames = availableIcons.map(\.imageName)
        let fallbackIconName =
            availableIconNames.first
            ?? Self.defaultProfileIconImageName
        let usesOldSpriteSheetDefault =
            selectedProfileIconImageName == Self.oldDefaultProfileIconImageName
        let usesMissingIcon =
            !availableIconNames.isEmpty
            && !availableIconNames.contains(selectedProfileIconImageName)

        guard usesOldSpriteSheetDefault || usesMissingIcon else { return }

        selectedProfileIconImageName = fallbackIconName
        saveProgress()
    }

    private func recalculateStageHPIfNeeded() {
        let expectedMaxHP = Self.maxHP(for: stage, accountLevel: accountLevel)

        if maxStageHP <= 0 || maxStageHP != expectedMaxHP {
            maxStageHP = expectedMaxHP
            stageHP = min(max(stageHP, 1), maxStageHP)
            saveProgress()
        }
    }

    private func recalculateStageHPForAccountLevel() {
        let expectedMaxHP = Self.maxHP(for: stage, accountLevel: accountLevel)
        guard expectedMaxHP != maxStageHP else { return }

        let missingHP = maxStageHP - stageHP
        maxStageHP = expectedMaxHP
        stageHP = max(maxStageHP - missingHP, 1)
    }

    private func resetEventIfNeeded(eventID: String) {
        let today = Self.todayKey()

        guard eventRunsByID[eventID]?.resetDay != today else { return }

        eventRunsByID[eventID] = EventRunProgress(
            eventID: eventID,
            usedRuns: 0,
            resetDay: today
        )
        saveProgress()
    }

    private static func maxHP(for stage: Int, accountLevel: Int) -> Int {
        let stageValue = max(stage, 0)
        let levelValue = max(accountLevel, 1)
        let baseHP = 12.0 * pow(1.24, Double(stageValue))
        let levelMultiplier = pow(1.10, Double(levelValue - 1))
        let variance = hpVarianceMultiplier(for: stageValue)
        return max(12, Int((baseHP * levelMultiplier * variance).rounded()))
    }

    private static func hpVarianceMultiplier(for stage: Int) -> Double {
        let seed = UInt64(max(stage, 0)) &* 1_103_515_245 &+ 12_345
        let bucket = Double(seed % 17)
        return 0.92 + bucket * 0.01
    }

    private static func xpToNextLevel(for level: Int) -> Int {
        Int((90.0 * pow(1.24, Double(max(level - 1, 0)))).rounded())
    }

    private static func rarityPower(_ rarity: SpriteRarity) -> Int {
        switch rarity {
        case .common:
            6
        case .rare:
            14
        case .epic:
            34
        case .legendary:
            82
        }
    }

    private static func scaledPower(base: Int, level: Int) -> Int {
        let multiplier = pow(1.46, Double(max(level - 1, 0)))
        return max(base, Int((Double(max(base, 1)) * multiplier).rounded()))
    }

    private func skillBonus(for effect: SkillEffect) -> Double {
        ownedSkillLevels.reduce(0) { total, entry in
            guard
                let skill = Self.skillConfiguration.skills.first(
                    where: { $0.id == entry.key && $0.effect == effect }
                )
            else {
                return total
            }

            return total + Double(entry.value) * skill.valuePerLevel
        }
    }

    private static func todayKey() -> String {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: Date()
        )
        return
            "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private struct ProgressSnapshot: Codable {
        let stage: Int
        let stageHP: Int
        let maxStageHP: Int
        let accountLevel: Int
        let accountXP: Int
        let prestigeCount: Int
        let artifactShards: Int
        let skillBooks: Int
        let coins: Int
        let crystals: Int
        let pendingCoins: Int
        let pendingCrystals: Int
        let ownedSprites: [OwnedSprite]
        let ownedCharacters: [OwnedCharacter]
        let unlockedCharacterSkinIDs: [String]
        let ownedArtifacts: [OwnedArtifact]
        let ownedItems: [OwnedItem]
        let eventCurrencies: [String: Int]
        let eventRunsByID: [String: EventRunProgress]
        let claimedGiftIDs: [String]
        let lastDailyLoginClaimDay: String
        let lastDailyLoginClaimDaysByID: [String: String]
        let selectedProfileIconImageName: String
        let selectedCharacterID: String
        let selectedCharacterSkinID: String
        let ownedSkillLevels: [String: Int]
        let passPointsByID: [String: Int]
        let claimedPassRewardIDs: [String]
        let premiumPassIDs: [String]
        let purchasedShopProductIDs: [String]
        let tradeOfferPurchaseCounts: [String: Int]
        let lastIdleRewardUpdate: TimeInterval

        init(
            stage: Int,
            stageHP: Int,
            maxStageHP: Int,
            accountLevel: Int,
            accountXP: Int,
            prestigeCount: Int,
            artifactShards: Int,
            skillBooks: Int,
            coins: Int,
            crystals: Int,
            pendingCoins: Int,
            pendingCrystals: Int,
            ownedSprites: [OwnedSprite],
            ownedCharacters: [OwnedCharacter],
            unlockedCharacterSkinIDs: [String],
            ownedArtifacts: [OwnedArtifact],
            ownedItems: [OwnedItem],
            eventCurrencies: [String: Int],
            eventRunsByID: [String: EventRunProgress],
            claimedGiftIDs: [String],
            lastDailyLoginClaimDay: String,
            lastDailyLoginClaimDaysByID: [String: String],
            selectedProfileIconImageName: String,
            selectedCharacterID: String,
            selectedCharacterSkinID: String,
            ownedSkillLevels: [String: Int],
            passPointsByID: [String: Int],
            claimedPassRewardIDs: [String],
            premiumPassIDs: [String],
            purchasedShopProductIDs: [String],
            tradeOfferPurchaseCounts: [String: Int],
            lastIdleRewardUpdate: TimeInterval
        ) {
            self.stage = stage
            self.stageHP = stageHP
            self.maxStageHP = maxStageHP
            self.accountLevel = accountLevel
            self.accountXP = accountXP
            self.prestigeCount = prestigeCount
            self.artifactShards = artifactShards
            self.skillBooks = skillBooks
            self.coins = coins
            self.crystals = crystals
            self.pendingCoins = pendingCoins
            self.pendingCrystals = pendingCrystals
            self.ownedSprites = ownedSprites
            self.ownedCharacters = ownedCharacters
            self.unlockedCharacterSkinIDs = unlockedCharacterSkinIDs
            self.ownedArtifacts = ownedArtifacts
            self.ownedItems = ownedItems
            self.eventCurrencies = eventCurrencies
            self.eventRunsByID = eventRunsByID
            self.claimedGiftIDs = claimedGiftIDs
            self.lastDailyLoginClaimDay = lastDailyLoginClaimDay
            self.lastDailyLoginClaimDaysByID = lastDailyLoginClaimDaysByID
            self.selectedProfileIconImageName = selectedProfileIconImageName
            self.selectedCharacterID = selectedCharacterID
            self.selectedCharacterSkinID = selectedCharacterSkinID
            self.ownedSkillLevels = ownedSkillLevels
            self.passPointsByID = passPointsByID
            self.claimedPassRewardIDs = claimedPassRewardIDs
            self.premiumPassIDs = premiumPassIDs
            self.purchasedShopProductIDs = purchasedShopProductIDs
            self.tradeOfferPurchaseCounts = tradeOfferPurchaseCounts
            self.lastIdleRewardUpdate = lastIdleRewardUpdate
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            stage = try container.decodeIfPresent(Int.self, forKey: .stage) ?? 0
            accountLevel =
                try container.decodeIfPresent(Int.self, forKey: .accountLevel)
                ?? 1
            maxStageHP =
                try container.decodeIfPresent(Int.self, forKey: .maxStageHP)
                ?? GameProgressStore.maxHP(
                    for: stage,
                    accountLevel: accountLevel
                )
            stageHP =
                try container.decodeIfPresent(Int.self, forKey: .stageHP)
                ?? maxStageHP
            accountXP =
                try container.decodeIfPresent(Int.self, forKey: .accountXP) ?? 0
            prestigeCount =
                try container.decodeIfPresent(Int.self, forKey: .prestigeCount)
                ?? 0
            artifactShards =
                try container.decodeIfPresent(Int.self, forKey: .artifactShards)
                ?? 0
            skillBooks =
                try container.decodeIfPresent(Int.self, forKey: .skillBooks)
                ?? 0
            coins = try container.decodeIfPresent(Int.self, forKey: .coins) ?? 0
            crystals =
                try container.decodeIfPresent(Int.self, forKey: .crystals) ?? 0
            pendingCoins =
                try container.decodeIfPresent(Int.self, forKey: .pendingCoins)
                ?? 0
            pendingCrystals =
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .pendingCrystals
                ) ?? 0
            ownedSprites =
                try container.decodeIfPresent(
                    [OwnedSprite].self,
                    forKey: .ownedSprites
                ) ?? []
            ownedCharacters =
                try container.decodeIfPresent(
                    [OwnedCharacter].self,
                    forKey: .ownedCharacters
                ) ?? []
            unlockedCharacterSkinIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .unlockedCharacterSkinIDs
                ) ?? []
            ownedArtifacts =
                try container.decodeIfPresent(
                    [OwnedArtifact].self,
                    forKey: .ownedArtifacts
                ) ?? []
            ownedItems =
                try container.decodeIfPresent(
                    [OwnedItem].self,
                    forKey: .ownedItems
                ) ?? []
            eventCurrencies =
                try container.decodeIfPresent(
                    [String: Int].self,
                    forKey: .eventCurrencies
                ) ?? [:]
            eventRunsByID =
                try container.decodeIfPresent(
                    [String: EventRunProgress].self,
                    forKey: .eventRunsByID
                ) ?? [:]
            claimedGiftIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .claimedGiftIDs
                ) ?? []
            lastDailyLoginClaimDay =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .lastDailyLoginClaimDay
                ) ?? ""
            lastDailyLoginClaimDaysByID =
                try container.decodeIfPresent(
                    [String: String].self,
                    forKey: .lastDailyLoginClaimDaysByID
                ) ?? [:]
            selectedProfileIconImageName =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedProfileIconImageName
                ) ?? GameProgressStore.defaultProfileIconImageName
            selectedCharacterID =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedCharacterID
                ) ?? GameProgressStore.defaultCharacterID
            selectedCharacterSkinID =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedCharacterSkinID
                ) ?? GameProgressStore.defaultCharacterSkinID
            ownedSkillLevels =
                try container.decodeIfPresent(
                    [String: Int].self,
                    forKey: .ownedSkillLevels
                ) ?? [:]
            passPointsByID =
                try container.decodeIfPresent(
                    [String: Int].self,
                    forKey: .passPointsByID
                ) ?? [:]
            claimedPassRewardIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .claimedPassRewardIDs
                ) ?? []
            premiumPassIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .premiumPassIDs
                ) ?? []
            purchasedShopProductIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .purchasedShopProductIDs
                ) ?? []
            tradeOfferPurchaseCounts =
                try container.decodeIfPresent(
                    [String: Int].self,
                    forKey: .tradeOfferPurchaseCounts
                ) ?? [:]
            lastIdleRewardUpdate =
                try container.decodeIfPresent(
                    TimeInterval.self,
                    forKey: .lastIdleRewardUpdate
                ) ?? Date().timeIntervalSince1970
        }
    }
}

struct OwnedSprite: Identifiable, Codable {
    var id: Int { spriteIndex }

    let spriteIndex: Int
    let name: String
    let imageName: String
    let rarity: SpriteRarity
    let stars: Int
}

struct OwnedCharacter: Identifiable, Codable {
    var id: String { characterID }

    let characterID: String
    let name: String
    let imageName: String
    let rarity: SpriteRarity
    let stars: Int
}

struct BattleAttackResult {
    let damageDealt: Int
    var coinsAwarded = 0
    var crystalsAwarded = 0
    var skillBooksAwarded = 0
}

struct BattleActiveSkill: Identifiable, Equatable {
    let id: String
    let title: String
    let imageName: String
    let kind: ActiveSkillKind
    let durationSeconds: Double
    let cooldownSeconds: Double
    let tickIntervalSeconds: Double
    let damage: Int
    let companionAnimationID: String?
}

private struct StageRewards {
    let coins: Int
    let crystals: Int
    let skillBooks: Int
}

struct SummonResult: Identifiable {
    let id = UUID()
    let entry: SummonEntry
    let kind: SummonKind
    let isDuplicate: Bool
    let level: Int
}

struct OwnedItem: Identifiable, Codable {
    var id: String { itemID }

    let itemID: String
    let name: String
    let imageName: String
    let rarity: SpriteRarity
    let damageBonus: Int
    let level: Int
}

struct ItemSummonResult: Identifiable {
    let id = UUID()
    let entry: SummonEntry
    let isDuplicate: Bool
    let level: Int
}

struct EventRunProgress: Codable {
    let eventID: String
    let usedRuns: Int
    let resetDay: String
}
