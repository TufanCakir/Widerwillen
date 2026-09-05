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
    private static let defaultHeroAnimationID = "nimbi_original"
    private static let defaultWeaponItemID = "widerwillen_sword"
    private static let selectedMenuBackgroundDefaultsKey =
        "selectedMenuBackgroundID"
    private static let selectedMenuButtonLookDefaultsKey =
        "selectedMenuButtonLookID"
    private static let didManuallySelectMenuBackgroundDefaultsKey =
        "didManuallySelectMenuBackground"
    private static let didManuallySelectMenuButtonLookDefaultsKey =
        "didManuallySelectMenuButtonLook"
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
    private static let summonConfiguration =
        (try? SummonConfiguration.load())
        ?? SummonConfiguration(banners: [])
    private static let spriteRigs =
        (try? SpriteRig.loadAll()) ?? []
    private static let menuBackgroundConfiguration =
        (try? MenuBackgroundConfiguration.load())
        ?? MenuBackgroundConfiguration.fallback

    private(set) var stage = 1
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
    private(set) var unlockedMenuBackgroundIDs: Set<String> = [
        MenuBackgroundConfiguration.defaultBackgroundID
    ]
    private(set) var unlockedMenuButtonLookIDs: Set<String> = [
        MenuBackgroundConfiguration.defaultButtonLookID
    ]
    private(set) var lastDailyLoginClaimDay = ""
    private(set) var lastDailyLoginClaimDaysByID: [String: String] = [:]
    private(set) var dailyLoginClaimCountsByID: [String: Int] = [:]
    private(set) var selectedProfileIconImageName =
        GameProgressStore.defaultProfileIconImageName
    private(set) var selectedCharacterID = GameProgressStore.defaultCharacterID
    private(set) var selectedCharacterSkinID =
        GameProgressStore.defaultCharacterSkinID
    private(set) var selectedCharacterPartSkinIDs: [String: String] = [:]
    private(set) var selectedWeaponItemID: String?
    private(set) var selectedMenuBackgroundID =
        MenuBackgroundConfiguration.defaultBackgroundID
    private(set) var selectedMenuButtonLookID =
        MenuBackgroundConfiguration.defaultButtonLookID
    private var lastIdleRewardUpdate = Date()

    init() {
        loadProgress()
        removeOldStarterCompanionIfNeeded()
        unlockDefaultCharacterIfNeeded()
        unlockDefaultWeaponIfNeeded()
        normalizeSelectedCharacterIfNeeded()
        normalizeSelectedSkinPartsIfNeeded()
        normalizeProfileIconSelectionIfNeeded()
        normalizeEquippedWeaponIfNeeded()
        normalizeMenuCosmeticsIfNeeded()
        recalculateStageHPIfNeeded()
        refreshIdleRewards()
    }

    func resetGameProgress() {
        let preservedPremiumPassIDs = premiumPassIDs
        let preservedPurchasedShopProductIDs = purchasedShopProductIDs

        UserDefaults.standard.removeObject(forKey: Self.saveKey)

        stage = 1
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
        unlockedMenuBackgroundIDs = [
            MenuBackgroundConfiguration.defaultBackgroundID
        ]
        unlockedMenuButtonLookIDs = [
            MenuBackgroundConfiguration.defaultButtonLookID
        ]
        lastDailyLoginClaimDay = ""
        lastDailyLoginClaimDaysByID = [:]
        dailyLoginClaimCountsByID = [:]
        selectedProfileIconImageName = Self.defaultProfileIconImageName
        selectedCharacterID = Self.defaultCharacterID
        selectedCharacterSkinID = Self.defaultCharacterSkinID
        selectedCharacterPartSkinIDs = [:]
        selectedWeaponItemID = nil
        selectedMenuBackgroundID =
            MenuBackgroundConfiguration.defaultBackgroundID
        selectedMenuButtonLookID =
            MenuBackgroundConfiguration.defaultButtonLookID
        lastIdleRewardUpdate = Date()

        unlockDefaultCharacterIfNeeded()
        unlockDefaultWeaponIfNeeded()
        normalizeSelectedCharacterIfNeeded()
        normalizeSelectedSkinPartsIfNeeded()
        normalizeProfileIconSelectionIfNeeded()
        normalizeEquippedWeaponIfNeeded()
        normalizeMenuCosmeticsIfNeeded()
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

    var battleHeroPartImageOverrides: [String: String] {
        selectedCharacterPartSkinIDs.reduce(into: [String: String]()) {
            result,
            entry in
            guard
                let part = CharacterBodyPart(rawValue: entry.key),
                let skin = Self.characterConfiguration.skin(
                    id: entry.value,
                    for: selectedCharacterID
                ),
                let imageName = Self.rigPartImageName(
                    for: part,
                    skin: skin
                )
            else {
                return
            }

            result[part.rigPartName] = imageName
        }
    }

    var availableMenuBackgrounds: [MenuBackgroundDefinition] {
        Self.menuBackgroundConfiguration.backgrounds.filter {
            unlockedMenuBackgroundIDs.contains($0.id)
        }
    }

    var availableMenuButtonLooks: [MenuButtonLookDefinition] {
        Self.menuBackgroundConfiguration.buttonLooks.filter {
            unlockedMenuButtonLookIDs.contains($0.id)
        }
    }

    var selectedMenuButtonLook: MenuButtonLookDefinition {
        availableMenuButtonLooks.first { $0.id == selectedMenuButtonLookID }
            ?? Self.menuBackgroundConfiguration.buttonLooks.first
            ?? MenuBackgroundConfiguration.fallback.buttonLooks[0]
    }

    func selectMenuBackground(_ background: MenuBackgroundDefinition) {
        guard unlockedMenuBackgroundIDs.contains(background.id) else { return }

        selectedMenuBackgroundID = background.id
        UserDefaults.standard.set(
            true,
            forKey: Self.didManuallySelectMenuBackgroundDefaultsKey
        )
        syncSelectedMenuBackgroundToDefaults()
        saveProgress()
    }

    func selectMenuButtonLook(_ look: MenuButtonLookDefinition) {
        guard unlockedMenuButtonLookIDs.contains(look.id) else { return }

        selectedMenuButtonLookID = look.id
        UserDefaults.standard.set(
            true,
            forKey: Self.didManuallySelectMenuButtonLookDefaultsKey
        )
        syncSelectedMenuButtonLookToDefaults()
        saveProgress()
    }

    var equippedWeapon: OwnedItem? {
        guard let selectedWeaponItemID else { return nil }
        return ownedItems[selectedWeaponItemID]
    }

    var equippedWeaponShadowCloneImageName: String? {
        guard let selectedWeaponItemID else {
            return nil
        }

        return Self.summonConfiguration.banners
            .flatMap(\.entries)
            .first { $0.id == selectedWeaponItemID }?
            .shadowCloneImageName
    }

    var equippedWeaponImageName: String? {
        equippedWeapon?.imageName
    }

    var equippedWeaponBattleAppearance: WeaponBattleAppearance? {
        guard let selectedWeaponItemID else {
            return nil
        }

        return Self.summonConfiguration.banners
            .flatMap(\.entries)
            .first { $0.id == selectedWeaponItemID }?
            .battleAppearance
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
        selectedCharacterPartSkinIDs = [:]
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
        selectedCharacterPartSkinIDs = [:]
        saveProgress()
    }

    func selectedSkin(for part: CharacterBodyPart) -> CharacterSkin? {
        guard let skinID = selectedCharacterPartSkinIDs[part.rawValue] else {
            return selectedCharacterSkin
        }

        return Self.characterConfiguration.skin(
            id: skinID,
            for: selectedCharacterID
        ) ?? selectedCharacterSkin
    }

    func imageName(for part: CharacterBodyPart, skin: CharacterSkin? = nil)
        -> String
    {
        let resolvedSkin = skin ?? selectedSkin(for: part)
        return resolvedSkin.flatMap {
            Self.rigPartImageName(for: part, skin: $0)
        } ?? resolvedSkin?.imageName
            ?? selectedCharacterSkin?.imageName
            ?? "icon_nimpi"
    }

    func isSelectedSkin(_ skin: CharacterSkin, for part: CharacterBodyPart)
        -> Bool
    {
        selectedCharacterPartSkinIDs[part.rawValue] == skin.id
    }

    func selectSkinPart(_ skin: CharacterSkin, for part: CharacterBodyPart) {
        guard isSkinUnlocked(skin),
            Self.characterConfiguration.skin(
                id: skin.id,
                for: selectedCharacterID
            ) != nil
        else {
            return
        }

        selectedCharacterPartSkinIDs[part.rawValue] = skin.id
        saveProgress()
    }

    func clearSkinPart(_ part: CharacterBodyPart) {
        selectedCharacterPartSkinIDs.removeValue(forKey: part.rawValue)
        saveProgress()
    }

    func isEquippedWeapon(_ item: OwnedItem) -> Bool {
        selectedWeaponItemID == item.itemID
    }

    func equipWeapon(_ item: OwnedItem) {
        guard ownedItems[item.itemID] != nil else { return }

        selectedWeaponItemID = item.itemID
        saveProgress()
    }

    var battlePower: Int {
        characterAttackPower
    }

    private var characterAttackPower: Int {
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
            $0
                + Self.scaledPower(
                    base: $1.damageBonus,
                    level: $1.level
                )
        }

        let itemPower = ownedItems.values.reduce(0) {
            $0
                + Self.scaledPower(
                    base: $1.damageBonus,
                    level: $1.level
                )
        }

        let accountPower = max(accountLevel - 1, 0) * 2
        let prestigePower = prestigeCount * 4

        let rawPower =
            heroPower
            + passiveCompanionPower
            + artifactPower
            + itemPower
            + accountPower
            + prestigePower

        return max(
            1,
            Int(
                (Double(rawPower)
                    * (1.0 + skillBonus(for: .damage))).rounded()
            )
        )
    }

    private var passiveCompanionPower: Int {
        ownedSprites.values.reduce(0) { total, sprite in
            let basePower =
                Self.companionConfiguration.companion(
                    spriteIndex: sprite.spriteIndex
                )?.baseDPS ?? Self.rarityPower(sprite.rarity)

            let power = Self.scaledPower(
                base: basePower,
                level: sprite.stars
            )

            return total + power
        }
    }

    var tapDamage: Int {
        let multiplier = 0.45 + skillBonus(for: .tapDamage)

        return max(
            1,
            Int(
                (Double(characterAttackPower) * multiplier)
                    .rounded()
            )
        )
    }

    var tapCooldownSeconds: Double {
        let speedBonus = min(skillBonus(for: .tapSpeed), 0.8)
        return max(0.08, 0.22 * (1.0 - speedBonus))
    }

    func passivePower(for sprite: OwnedSprite) -> Int {
        let basePower =
            Self.companionConfiguration.companion(
                spriteIndex: sprite.spriteIndex
            )?.baseDPS ?? Self.rarityPower(sprite.rarity)

        return Self.scaledPower(
            base: basePower,
            level: sprite.stars
        )
    }

    var activeBattleSkills: [BattleActiveSkill] {
        Self.skillConfiguration.skills.compactMap { skill in
            guard
                let activation = skill.activation,
                skillLevel(for: skill) > 0
            else {
                return nil
            }

            let damageMultiplier =
                activation.damageMultiplier
                * (1.0 + skillBonus(for: .shadowCloneDamage))
            let intervalMultiplier =
                1.0 - min(skillBonus(for: .attackSpeed), 0.75)
            let damage = max(
                1,
                Int(
                    (Double(characterAttackPower) * damageMultiplier)
                        .rounded()
                )
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
                tickIntervalSeconds: max(
                    0.12,
                    activation.intervalSeconds * intervalMultiplier
                ),
                damage: damage,
                companionAnimationID: activation.companionAnimationID
            )
        }
    }

    var hasPendingRewards: Bool {
        pendingCoins > 0 || pendingCrystals > 0
    }

    var idleCoinsPerMinute: Int {
        let powerBonus = Int(sqrt(Double(max(battlePower, 0))) * 2.0)
        return max(5, accountLevel * 4 + stage * 2 + powerBonus)
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

    func prepareStageForBattleStart() {
        let expectedMaxHP = Self.maxHP(for: stage, accountLevel: accountLevel)
        maxStageHP = expectedMaxHP
        stageHP = expectedMaxHP
        saveProgress()
    }

    @discardableResult
    func attackStage(damage: Int? = nil) -> BattleAttackResult {
        let baseDamageValue = max(damage ?? tapDamage, 1)
        let isCriticalHit = rollCriticalHit()
        let damageValue =
            isCriticalHit
            ? max(
                baseDamageValue,
                Int(
                    (Double(baseDamageValue)
                        * criticalDamageMultiplier).rounded()
                )
            )
            : baseDamageValue
        let damageDealt = min(stageHP, damageValue)
        stageHP = max(stageHP - damageValue, 0)

        if stageHP == 0 {
            let extraClears = rollMultiHitClearCount()
            let rewards = advanceStage(extraClears: extraClears)
            return BattleAttackResult(
                damageDealt: damageDealt,
                coinsAwarded: rewards.coins,
                crystalsAwarded: rewards.crystals,
                skillBooksAwarded: rewards.skillBooks,
                stagesCleared: rewards.stagesCleared,
                isCriticalHit: isCriticalHit,
                extraStagesCleared: extraClears
            )
        } else {
            saveProgress()
            return BattleAttackResult(
                damageDealt: damageDealt,
                isCriticalHit: isCriticalHit
            )
        }
    }

    private func advanceStage(extraClears: Int = 0) -> StageRewards {
        let previousStage = stage
        let nextStage = stage + 1
        let skippedStages = rollStageSkipCount(from: nextStage)
        let extraStages = max(extraClears, 0)
        let reachedStage = nextStage + skippedStages + extraStages
        let stageDropMultiplier = 1.0 + Double(reachedStage) * 0.015
        let earnedCoins = Int(
            (Double(28 + reachedStage * 4)
                * stageDropMultiplier
                * (1.0 + skillBonus(for: .coinDrop))
                * (1.0 + Double(skippedStages + extraStages) * 0.65)).rounded()
        )
        let bossStagesCleared = (nextStage...reachedStage)
            .filter { $0.isMultiple(of: 10) }
            .count
        let crystalDropChance = min(
            0.04 + Double(reachedStage) * 0.0015
                + skillBonus(for: .dropChance) * 0.25,
            0.32
        )
        let randomCrystals =
            Double.random(in: 0..<1) < crystalDropChance
            ? max(1, reachedStage / 35 + 1)
            : 0
        let earnedCrystals =
            bossStagesCleared > 0
            ? bossStagesCleared + reachedStage / 35 + randomCrystals
            : randomCrystals
        let earnedSkillBooks = rollSkillBookDrop(for: reachedStage)

        stage = reachedStage
        coins += earnedCoins
        skillBooks += earnedSkillBooks
        addAccountXP(12 + reachedStage * 2 + (skippedStages + extraStages) * 5)
        maxStageHP = Self.maxHP(for: reachedStage, accountLevel: accountLevel)
        stageHP = maxStageHP

        crystals += earnedCrystals
        addPassPoints(
            (bossStagesCleared > 0 ? 30 : 10)
                + (skippedStages + extraStages) * 10
        )

        saveProgress()
        return StageRewards(
            coins: earnedCoins,
            crystals: earnedCrystals,
            skillBooks: earnedSkillBooks,
            stagesCleared: reachedStage - previousStage
        )
    }

    private var criticalDamageMultiplier: Double {
        max(1.5, 1.5 + skillBonus(for: .critDamage))
    }

    private func rollCriticalHit() -> Bool {
        let chance = min(skillBonus(for: .critChance), 0.65)
        return chance > 0 && Double.random(in: 0..<1) < chance
    }

    private func rollMultiHitClearCount() -> Int {
        let chance = min(skillBonus(for: .multiHitChance), 0.5)
        guard chance > 0, Double.random(in: 0..<1) < chance else {
            return 0
        }

        let maxExtraClears = max(
            1,
            Int(skillBonus(for: .multiHitCount).rounded(.down))
        )
        return Int.random(in: 1...min(maxExtraClears, 4))
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
        skillBooks += event.rewards.skillBooks
        for unlock in event.unlocks {
            applyTradeUnlock(unlock)
        }
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
        let elapsedSeconds = min(
            max(0, now.timeIntervalSince(lastIdleRewardUpdate)),
            8 * 60 * 60
        )
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

        for unlock in gift.unlocks {
            applyTradeUnlock(unlock)
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

            for unlock in gift.unlocks {
                applyTradeUnlock(unlock)
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

        return rewards.sorted { $0.day < $1.day }.first
    }

    func currentDailyLoginReward(in login: DailyLoginCampaign)
        -> DailyLoginReward?
    {
        let rewards = login.rewards.sorted { $0.day < $1.day }
        guard !rewards.isEmpty else { return nil }

        let claimCount = max(dailyLoginClaimCountsByID[login.id] ?? 0, 0)
        let alreadyClaimedToday = !canClaimDailyLogin(for: login)
        let displayIndex =
            alreadyClaimedToday
            ? max(claimCount - 1, 0)
            : claimCount

        return rewards[displayIndex % rewards.count]
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

        for unlock in reward.unlocks {
            applyTradeUnlock(unlock)
        }

        lastDailyLoginClaimDay = Self.todayKey()
        dailyLoginClaimCountsByID["standard", default: 0] += 1
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

        for unlock in reward.unlocks {
            applyTradeUnlock(unlock)
        }

        let today = Self.todayKey()
        lastDailyLoginClaimDaysByID[login.id] = today
        dailyLoginClaimCountsByID[login.id, default: 0] += 1
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
            change(amount, by: amount.amount)
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

    func addPurchasedResources(_ rewards: [TradeResourceAmount]) {
        for reward in rewards where reward.resource != .eventChip {
            change(reward.resource, by: reward.amount)
        }

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

    func skillLevel(forSkillID skillID: String) -> Int {
        ownedSkillLevels[skillID, default: 0]
    }

    func requiredAccountLevel(forSkillID skillID: String) -> Int? {
        Self.skillConfiguration.skills.first { $0.id == skillID }?
            .requiredAccountLevel
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
            if selectedWeaponItemID == nil || oldLevel == 0 {
                selectedWeaponItemID = entry.id
            }
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
        case .sprite:
            if let spriteIndex = unlock.spriteIndex {
                unlockSprite(
                    spriteIndex: spriteIndex,
                    name: unlock.name,
                    imageName: unlock.imageName,
                    rarity: unlock.rarity ?? .rare
                )
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
            if selectedWeaponItemID == nil {
                selectedWeaponItemID = itemID
            }
        case .appBackground, .menuBackground:
            unlockMenuBackground(unlock.id)
        case .menuButton:
            unlockMenuButtonLook(unlock.id)
        }
    }

    private func unlockMenuBackground(_ backgroundID: String) {
        let knownIDs = Set(
            Self.menuBackgroundConfiguration.backgrounds.map(\.id)
        )
        guard knownIDs.contains(backgroundID) else { return }

        unlockedMenuBackgroundIDs.insert(backgroundID)
    }

    private func unlockMenuButtonLook(_ buttonLookID: String) {
        let knownIDs = Set(
            Self.menuBackgroundConfiguration.buttonLooks.map(\.id)
        )
        guard knownIDs.contains(buttonLookID) else { return }

        unlockedMenuButtonLookIDs.insert(buttonLookID)
    }

    private func unlockSprite(
        spriteIndex: Int,
        name: String,
        imageName: String,
        rarity: SpriteRarity
    ) {
        let companion =
            Self.companionConfiguration.companion(spriteIndex: spriteIndex)
        let oldStars = ownedSprites[spriteIndex]?.stars ?? 0
        ownedSprites[spriteIndex] = OwnedSprite(
            spriteIndex: spriteIndex,
            name: companion?.name ?? name,
            imageName: companion?.imageName ?? imageName,
            rarity: companion?.rarity ?? rarity,
            stars: oldStars + 1
        )
    }

    private func rollSkillBookDrop(for stage: Int) -> Int {
        let stageValue = max(stage, 1)
        let isBossStage = stageValue.isMultiple(of: 10)
        let guaranteedBooks = stageValue / 25
        let bossBonus = isBossStage ? max(1, stageValue / 40) : 0
        let chance = min(
            (isBossStage ? 0.28 : 0.12)
                + Double(stageValue) * 0.003
                + skillBonus(for: .dropChance),
            0.72
        )
        let randomBooks = Double.random(in: 0..<1) < chance ? 1 : 0

        return guaranteedBooks + bossBonus + randomBooks
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

    private static func rigPartImageName(
        for part: CharacterBodyPart,
        skin: CharacterSkin
    ) -> String? {
        spriteRigs.first { $0.id == skin.animationID }?
            .parts[part.rigPartName]
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
        unlockedMenuBackgroundIDs = Set(snapshot.unlockedMenuBackgroundIDs)
        unlockedMenuButtonLookIDs = Set(snapshot.unlockedMenuButtonLookIDs)
        lastDailyLoginClaimDay = snapshot.lastDailyLoginClaimDay
        lastDailyLoginClaimDaysByID = snapshot.lastDailyLoginClaimDaysByID
        dailyLoginClaimCountsByID = snapshot.dailyLoginClaimCountsByID
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
        selectedCharacterPartSkinIDs = snapshot.selectedCharacterPartSkinIDs
        selectedWeaponItemID = snapshot.selectedWeaponItemID
        selectedMenuBackgroundID = snapshot.selectedMenuBackgroundID
        selectedMenuButtonLookID = snapshot.selectedMenuButtonLookID
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
        normalizeEquippedWeaponIfNeeded()
        normalizeMenuCosmeticsIfNeeded()
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
            unlockedMenuBackgroundIDs: Array(unlockedMenuBackgroundIDs),
            unlockedMenuButtonLookIDs: Array(unlockedMenuButtonLookIDs),
            lastDailyLoginClaimDay: lastDailyLoginClaimDay,
            lastDailyLoginClaimDaysByID: lastDailyLoginClaimDaysByID,
            dailyLoginClaimCountsByID: dailyLoginClaimCountsByID,
            selectedProfileIconImageName: selectedProfileIconImageName,
            selectedCharacterID: selectedCharacterID,
            selectedCharacterSkinID: selectedCharacterSkinID,
            selectedCharacterPartSkinIDs: selectedCharacterPartSkinIDs,
            selectedWeaponItemID: selectedWeaponItemID,
            selectedMenuBackgroundID: selectedMenuBackgroundID,
            selectedMenuButtonLookID: selectedMenuButtonLookID,
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

    private func unlockDefaultWeaponIfNeeded() {
        guard ownedItems[Self.defaultWeaponItemID] == nil,
            let starterWeapon = Self.summonConfiguration.banners
                .first(where: { $0.kind == .item })?
                .entries
                .first(where: { $0.id == Self.defaultWeaponItemID })
        else {
            return
        }

        ownedItems[starterWeapon.id] = OwnedItem(
            itemID: starterWeapon.id,
            name: starterWeapon.name,
            imageName: starterWeapon.imageName,
            rarity: starterWeapon.rarity,
            damageBonus: starterWeapon.damageBonus,
            level: 1
        )

        if selectedWeaponItemID == nil {
            selectedWeaponItemID = starterWeapon.id
        }

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

    private func normalizeSelectedSkinPartsIfNeeded() {
        selectedCharacterPartSkinIDs = selectedCharacterPartSkinIDs.filter {
            entry in
            guard let part = CharacterBodyPart(rawValue: entry.key),
                unlockedCharacterSkinIDs.contains(entry.value),
                let skin = Self.characterConfiguration.skin(
                    id: entry.value,
                    for: selectedCharacterID
                )
            else {
                return false
            }

            return Self.rigPartImageName(for: part, skin: skin) != nil
        }
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

    private func normalizeMenuCosmeticsIfNeeded() {
        unlockedMenuBackgroundIDs.insert(
            MenuBackgroundConfiguration.defaultBackgroundID
        )
        unlockedMenuButtonLookIDs.insert(
            MenuBackgroundConfiguration.defaultButtonLookID
        )

        let knownBackgroundIDs = Set(
            Self.menuBackgroundConfiguration.backgrounds.map(\.id)
        )
        let knownButtonLookIDs = Set(
            Self.menuBackgroundConfiguration.buttonLooks.map(\.id)
        )

        unlockedMenuBackgroundIDs = unlockedMenuBackgroundIDs.filter {
            knownBackgroundIDs.contains($0)
        }
        unlockedMenuButtonLookIDs = unlockedMenuButtonLookIDs.filter {
            knownButtonLookIDs.contains($0)
        }

        let didManuallySelectMenuBackground = UserDefaults.standard.bool(
            forKey: Self.didManuallySelectMenuBackgroundDefaultsKey
        )
        let didManuallySelectMenuButtonLook = UserDefaults.standard.bool(
            forKey: Self.didManuallySelectMenuButtonLookDefaultsKey
        )

        if !didManuallySelectMenuBackground {
            selectedMenuBackgroundID =
                MenuBackgroundConfiguration.defaultBackgroundID
        } else if !unlockedMenuBackgroundIDs.contains(selectedMenuBackgroundID)
        {
            selectedMenuBackgroundID =
                MenuBackgroundConfiguration.defaultBackgroundID
        }

        if !didManuallySelectMenuButtonLook {
            selectedMenuButtonLookID =
                MenuBackgroundConfiguration.defaultButtonLookID
        } else if !unlockedMenuButtonLookIDs.contains(selectedMenuButtonLookID)
        {
            selectedMenuButtonLookID =
                MenuBackgroundConfiguration.defaultButtonLookID
        }

        syncSelectedMenuBackgroundToDefaults()
        syncSelectedMenuButtonLookToDefaults()
        saveProgress()
    }

    private func syncSelectedMenuBackgroundToDefaults() {
        UserDefaults.standard.set(
            selectedMenuBackgroundID,
            forKey: Self.selectedMenuBackgroundDefaultsKey
        )
    }

    private func syncSelectedMenuButtonLookToDefaults() {
        UserDefaults.standard.set(
            selectedMenuButtonLookID,
            forKey: Self.selectedMenuButtonLookDefaultsKey
        )
    }

    private func normalizeEquippedWeaponIfNeeded() {
        unlockDefaultWeaponIfNeeded()

        if let selectedWeaponItemID,
            ownedItems[selectedWeaponItemID] != nil
        {
            return
        }

        selectedWeaponItemID =
            ownedItems.values.max {
                lhs,
                rhs in
                let lhsPower = Self.scaledPower(
                    base: lhs.damageBonus,
                    level: lhs.level
                )
                let rhsPower = Self.scaledPower(
                    base: rhs.damageBonus,
                    level: rhs.level
                )
                return lhsPower < rhsPower
            }?.itemID
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
        let stageValue = max(stage, 1)
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
        let unlockedMenuBackgroundIDs: [String]
        let unlockedMenuButtonLookIDs: [String]
        let lastDailyLoginClaimDay: String
        let lastDailyLoginClaimDaysByID: [String: String]
        let dailyLoginClaimCountsByID: [String: Int]
        let selectedProfileIconImageName: String
        let selectedCharacterID: String
        let selectedCharacterSkinID: String
        let selectedCharacterPartSkinIDs: [String: String]
        let selectedWeaponItemID: String?
        let selectedMenuBackgroundID: String
        let selectedMenuButtonLookID: String
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
            unlockedMenuBackgroundIDs: [String],
            unlockedMenuButtonLookIDs: [String],
            lastDailyLoginClaimDay: String,
            lastDailyLoginClaimDaysByID: [String: String],
            dailyLoginClaimCountsByID: [String: Int],
            selectedProfileIconImageName: String,
            selectedCharacterID: String,
            selectedCharacterSkinID: String,
            selectedCharacterPartSkinIDs: [String: String],
            selectedWeaponItemID: String?,
            selectedMenuBackgroundID: String,
            selectedMenuButtonLookID: String,
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
            self.unlockedMenuBackgroundIDs = unlockedMenuBackgroundIDs
            self.unlockedMenuButtonLookIDs = unlockedMenuButtonLookIDs
            self.lastDailyLoginClaimDay = lastDailyLoginClaimDay
            self.lastDailyLoginClaimDaysByID = lastDailyLoginClaimDaysByID
            self.dailyLoginClaimCountsByID = dailyLoginClaimCountsByID
            self.selectedProfileIconImageName = selectedProfileIconImageName
            self.selectedCharacterID = selectedCharacterID
            self.selectedCharacterSkinID = selectedCharacterSkinID
            self.selectedCharacterPartSkinIDs = selectedCharacterPartSkinIDs
            self.selectedWeaponItemID = selectedWeaponItemID
            self.selectedMenuBackgroundID = selectedMenuBackgroundID
            self.selectedMenuButtonLookID = selectedMenuButtonLookID
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
            stage = max(
                try container.decodeIfPresent(Int.self, forKey: .stage) ?? 1,
                1
            )
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
            unlockedMenuBackgroundIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .unlockedMenuBackgroundIDs
                ) ?? [MenuBackgroundConfiguration.defaultBackgroundID]
            unlockedMenuButtonLookIDs =
                try container.decodeIfPresent(
                    [String].self,
                    forKey: .unlockedMenuButtonLookIDs
                ) ?? [MenuBackgroundConfiguration.defaultButtonLookID]
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
            dailyLoginClaimCountsByID =
                try container.decodeIfPresent(
                    [String: Int].self,
                    forKey: .dailyLoginClaimCountsByID
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
            selectedCharacterPartSkinIDs =
                try container.decodeIfPresent(
                    [String: String].self,
                    forKey: .selectedCharacterPartSkinIDs
                ) ?? [:]
            selectedWeaponItemID =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedWeaponItemID
                )
            selectedMenuBackgroundID =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedMenuBackgroundID
                ) ?? MenuBackgroundConfiguration.defaultBackgroundID
            selectedMenuButtonLookID =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedMenuButtonLookID
                ) ?? MenuBackgroundConfiguration.defaultButtonLookID
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
    var relicsAwarded = 0
    var skillBooksAwarded = 0
    var eventChipsAwarded = 0
    var eventChipImageName: String?
    var stagesCleared = 0
    var isCriticalHit = false
    var extraStagesCleared = 0
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
    let stagesCleared: Int
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
