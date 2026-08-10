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

    private(set) var stage = 0
    private(set) var stageHP = 12
    private(set) var maxStageHP = 12
    private(set) var accountLevel = 1
    private(set) var accountXP = 0
    private(set) var accountXPToNextLevel = 100
    private(set) var prestigeCount = 0
    private(set) var artifactShards = 0
    private(set) var coins = 0
    private(set) var crystals = 0
    private(set) var pendingCoins = 0
    private(set) var pendingCrystals = 0
    private(set) var ownedSprites: [Int: OwnedSprite] = [:]
    private(set) var ownedArtifacts: [String: OwnedArtifact] = [:]
    private(set) var ownedItems: [String: OwnedItem] = [:]
    private(set) var lastSummonResults: [SummonResult] = []
    private(set) var lastArtifactSummonResults: [ArtifactSummonResult] = []
    private(set) var lastItemSummonResults: [ItemSummonResult] = []
    private(set) var eventCurrencies: [String: Int] = [:]
    private(set) var eventRunsByID: [String: EventRunProgress] = [:]
    private(set) var claimedGiftIDs: Set<String> = []
    private(set) var lastDailyLoginClaimDay = ""
    private(set) var selectedProfileIconImageName = "sprite_cookieman"
    private var lastIdleRewardUpdate = Date()

    var isAutoBattleEnabled = true

    init() {
        loadProgress()
        unlockStarterIfNeeded()
        recalculateStageHPIfNeeded()
        refreshIdleRewards()
    }

    var unlockedSpriteIndices: Set<Int> {
        Set(ownedSprites.keys)
    }

    var battlePower: Int {
        let spritePower = ownedSprites.values.reduce(0) {
            $0
                + Self.scaledPower(
                    base: Self.rarityPower($1.rarity),
                    level: $1.stars
                )
        }
        let artifactPower = ownedArtifacts.values.reduce(0) {
            $0 + Self.scaledPower(base: $1.damageBonus, level: $1.level)
        }
        let itemPower = ownedItems.values.reduce(0) {
            $0 + Self.scaledPower(base: $1.damageBonus, level: $1.level)
        }
        let accountPower = max(accountLevel - 1, 0) * 2
        let prestigePower = prestigeCount * 5
        return max(
            1,
            spritePower + artifactPower + itemPower + accountPower
                + prestigePower
        )
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

    func attackStage() {
        stageHP = max(stageHP - battlePower, 0)

        if stageHP == 0 {
            advanceStage()
        } else {
            saveProgress()
        }
    }

    private func advanceStage() {
        let nextStage = stage + 1
        stage = nextStage
        coins += 25 + nextStage * 3
        addAccountXP(12 + nextStage * 2)
        maxStageHP = Self.maxHP(for: nextStage, accountLevel: accountLevel)
        stageHP = maxStageHP

        if nextStage.isMultiple(of: 10) {
            crystals += 1 + nextStage / 50
        }

        saveProgress()
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
        eventCurrencies[event.id, default: 0] += event.rewards.eventCurrency
        coins += event.rewards.coins
        crystals += event.rewards.crystals
        artifactShards += event.rewards.relics
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
            change(reward.resource, by: reward.amount)
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
                change(reward.resource, by: reward.amount)
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

    @discardableResult
    func claimDailyLoginReward(_ reward: DailyLoginReward) -> Bool {
        guard canClaimDailyLogin else { return false }

        for amount in reward.rewards {
            change(amount.resource, by: amount.amount)
        }

        lastDailyLoginClaimDay = Self.todayKey()
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
        }
    }

    func canApplyTradeOffer(_ offer: TradeOffer) -> Bool {
        offer.costs.allSatisfy { amount(for: $0.resource) >= $0.amount }
    }

    @discardableResult
    func applyTradeOffer(_ offer: TradeOffer) -> Bool {
        guard canApplyTradeOffer(offer) else { return false }

        for cost in offer.costs {
            change(cost.resource, by: -cost.amount)
        }

        for reward in offer.rewards {
            change(reward.resource, by: reward.amount)
        }

        saveProgress()
        return true
    }

    func prestige() {
        guard canPrestige else { return }

        let earnedShards = max(1, stage / 10)
        prestigeCount += 1
        artifactShards += earnedShards
        stage = 0
        maxStageHP = Self.maxHP(for: stage, accountLevel: accountLevel)
        stageHP = maxStageHP
        saveProgress()
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
            let spriteIndex = entry.spriteIndex ?? 0
            let oldStars = ownedSprites[spriteIndex]?.stars ?? 0
            let newStars = oldStars + 1
            ownedSprites[spriteIndex] = OwnedSprite(
                spriteIndex: spriteIndex,
                name: entry.name,
                imageName: entry.imageName,
                rarity: entry.rarity,
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
        }
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
        coins = snapshot.coins
        crystals = snapshot.crystals
        pendingCoins = snapshot.pendingCoins
        pendingCrystals = snapshot.pendingCrystals
        eventCurrencies = snapshot.eventCurrencies
        eventRunsByID = snapshot.eventRunsByID
        claimedGiftIDs = Set(snapshot.claimedGiftIDs)
        lastDailyLoginClaimDay = snapshot.lastDailyLoginClaimDay
        selectedProfileIconImageName = snapshot.selectedProfileIconImageName
        lastIdleRewardUpdate = Date(
            timeIntervalSince1970: snapshot.lastIdleRewardUpdate
        )
        ownedSprites = Dictionary(
            uniqueKeysWithValues: snapshot.ownedSprites.map {
                ($0.spriteIndex, $0)
            }
        )
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
            coins: coins,
            crystals: crystals,
            pendingCoins: pendingCoins,
            pendingCrystals: pendingCrystals,
            ownedSprites: Array(ownedSprites.values),
            ownedArtifacts: Array(ownedArtifacts.values),
            ownedItems: Array(ownedItems.values),
            eventCurrencies: eventCurrencies,
            eventRunsByID: eventRunsByID,
            claimedGiftIDs: Array(claimedGiftIDs),
            lastDailyLoginClaimDay: lastDailyLoginClaimDay,
            selectedProfileIconImageName: selectedProfileIconImageName,
            lastIdleRewardUpdate: lastIdleRewardUpdate.timeIntervalSince1970
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
    }

    private func unlockStarterIfNeeded() {
        guard ownedSprites[0] == nil else { return }

        ownedSprites[0] = OwnedSprite(
            spriteIndex: 0,
            name: "Cookieman",
            imageName: "sprite_cookieman",
            rarity: .common,
            stars: 1
        )
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
        return max(12, Int((baseHP * levelMultiplier).rounded()))
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
        let coins: Int
        let crystals: Int
        let pendingCoins: Int
        let pendingCrystals: Int
        let ownedSprites: [OwnedSprite]
        let ownedArtifacts: [OwnedArtifact]
        let ownedItems: [OwnedItem]
        let eventCurrencies: [String: Int]
        let eventRunsByID: [String: EventRunProgress]
        let claimedGiftIDs: [String]
        let lastDailyLoginClaimDay: String
        let selectedProfileIconImageName: String
        let lastIdleRewardUpdate: TimeInterval

        init(
            stage: Int,
            stageHP: Int,
            maxStageHP: Int,
            accountLevel: Int,
            accountXP: Int,
            prestigeCount: Int,
            artifactShards: Int,
            coins: Int,
            crystals: Int,
            pendingCoins: Int,
            pendingCrystals: Int,
            ownedSprites: [OwnedSprite],
            ownedArtifacts: [OwnedArtifact],
            ownedItems: [OwnedItem],
            eventCurrencies: [String: Int],
            eventRunsByID: [String: EventRunProgress],
            claimedGiftIDs: [String],
            lastDailyLoginClaimDay: String,
            selectedProfileIconImageName: String,
            lastIdleRewardUpdate: TimeInterval
        ) {
            self.stage = stage
            self.stageHP = stageHP
            self.maxStageHP = maxStageHP
            self.accountLevel = accountLevel
            self.accountXP = accountXP
            self.prestigeCount = prestigeCount
            self.artifactShards = artifactShards
            self.coins = coins
            self.crystals = crystals
            self.pendingCoins = pendingCoins
            self.pendingCrystals = pendingCrystals
            self.ownedSprites = ownedSprites
            self.ownedArtifacts = ownedArtifacts
            self.ownedItems = ownedItems
            self.eventCurrencies = eventCurrencies
            self.eventRunsByID = eventRunsByID
            self.claimedGiftIDs = claimedGiftIDs
            self.lastDailyLoginClaimDay = lastDailyLoginClaimDay
            self.selectedProfileIconImageName = selectedProfileIconImageName
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
            selectedProfileIconImageName =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .selectedProfileIconImageName
                ) ?? "sprite_cookieman"
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
