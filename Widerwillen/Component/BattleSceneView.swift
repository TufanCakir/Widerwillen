//
//  BattleSceneView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SpriteKit
import SwiftUI

struct BattleSceneView: View {
    let progress: GameProgressStore
    let title: String
    let healthTitle: String
    let currentHP: Int
    let maxHP: Int
    let lookIndex: Int
    let heroAnimationID: String
    let equippedWeaponImageName: String?
    let equippedWeaponBattleAppearance: WeaponBattleAppearance?
    let activeSkills: [BattleActiveSkill]
    let backgroundImageName: String?
    let groundImageName: String?
    let onTapAttack: () -> BattleAttackResult
    let onBattleCardAttack: ((BattleCardDefinition) -> BattleAttackResult)?
    let onActiveSkillAttack: (BattleActiveSkill) -> BattleAttackResult
    let onPrestige: (() -> Void)?
    let onExit: (() -> Void)?

    private let arena: ArenaConfiguration
    private let background: BackgroundConfiguration
    private let enemies: EnemyConfiguration
    private let battleCards: BattleCardConfiguration

    @State private var scene: SpriteAnimationScene
    @State private var selectedLookIndex: Int
    @State private var animationStartDate = Date()
    @State private var previousAreaID: String?
    @State private var transitionArea: EnemyArea?
    @State private var activeSkillIDs: Set<String> = []
    @State private var coolingDownSkillIDs: Set<String> = []
    @State private var coolingDownCardIDs: Set<String> = []
    @State private var cardCooldownEndDates: [String: Date] = [:]
    @State private var skillCooldownEndDates: [String: Date] = [:]
    @State private var cooldownClockDate = Date()
    @State private var lastTapAttackDate = Date.distantPast
    @AppStorage("isLayerAnimationEnabled") private var isLayerAnimationEnabled =
        true

    init(
        progress: GameProgressStore,
        title: String,
        healthTitle: String,
        currentHP: Int,
        maxHP: Int,
        lookIndex: Int,
        heroAnimationID: String,
        equippedWeaponImageName: String? = nil,
        equippedWeaponBattleAppearance: WeaponBattleAppearance? = nil,
        activeSkills: [BattleActiveSkill] = [],
        backgroundImageName: String? = nil,
        groundImageName: String? = nil,
        onTapAttack: @escaping () -> BattleAttackResult,
        onBattleCardAttack: ((BattleCardDefinition) -> BattleAttackResult)? =
            nil,
        onActiveSkillAttack:
            @escaping (BattleActiveSkill)
            -> BattleAttackResult = { _ in BattleAttackResult(damageDealt: 0) },
        onPrestige: (() -> Void)? = nil,
        onExit: (() -> Void)? = nil,
        arena: ArenaConfiguration = try! ArenaConfiguration.load(),
        background: BackgroundConfiguration =
            try! BackgroundConfiguration.load(),
        enemies: EnemyConfiguration =
            (try? EnemyConfiguration.load()) ?? EnemyConfiguration(areas: []),
        battleCards: BattleCardConfiguration =
            (try? BattleCardConfiguration.load())
            ?? BattleCardConfiguration(cards: [])
    ) {
        self.progress = progress
        self.title = title
        self.healthTitle = healthTitle
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.lookIndex = lookIndex
        self.heroAnimationID = heroAnimationID
        self.equippedWeaponImageName = equippedWeaponImageName
        self.equippedWeaponBattleAppearance = equippedWeaponBattleAppearance
        self.activeSkills = activeSkills
        self.backgroundImageName = backgroundImageName
        self.groundImageName = groundImageName
        self.onTapAttack = onTapAttack
        self.onBattleCardAttack = onBattleCardAttack
        self.onActiveSkillAttack = onActiveSkillAttack
        self.onPrestige = onPrestige
        self.onExit = onExit
        self.arena = arena
        self.background = background
        self.enemies = enemies
        self.battleCards = battleCards
        _scene = State(
            initialValue: SpriteAnimationScene.makeDefaultScene(arena: arena)
        )
        _selectedLookIndex = State(initialValue: lookIndex)
    }

    var body: some View {
        GeometryReader { proxy in
            let viewSize = proxy.size
            let groundHeight = viewSize.height * arena.floorHeightRatio
            let backgroundLook = selectedBackgroundLook
            let groundLook = selectedGroundLook
            let hudTopPadding = max(proxy.safeAreaInsets.top + 10, 54)
            let sideButtonTopPadding = max(
                proxy.safeAreaInsets.top + 140,
                viewSize.height * 0.22
            )
            let cardBottomPadding = max(proxy.safeAreaInsets.bottom + 10, 24)

            ZStack(alignment: .bottom) {
                backgroundLayer(look: backgroundLook, viewSize: viewSize)
                backgroundDarkeningLayer(look: backgroundLook)

                groundLayer(
                    look: groundLook,
                    viewSize: viewSize,
                    groundHeight: groundHeight
                )
                groundDarkeningLayer(
                    look: groundLook,
                    groundHeight: groundHeight
                )

                SpriteView(scene: scene, options: [.allowsTransparency])

                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        performTapAttack(in: viewSize)
                    }
                    .zIndex(1)

                BattleHUD(
                    progress: progress,
                    title: title,
                    healthTitle: healthTitle,
                    currentHP: currentHP,
                    maxHP: maxHP
                )
                .padding(.horizontal)
                .padding(.top, hudTopPadding)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .top
                )

                VStack(spacing: 10) {
                    if let onExit {
                        exitButton(onExit: onExit)
                    }

                    if let onPrestige, progress.canPrestige {
                        prestigeButton(onPrestige: onPrestige)
                    }
                }
                .padding(.top, sideButtonTopPadding)
                .padding(.trailing, 18)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topTrailing
                )
                .zIndex(12)

                BattleCardBar(
                    progress: progress,
                    battleCards: battleCards,
                    activeSkills: activeSkills,
                    activeSkillIDs: activeSkillIDs,
                    cooldownClockDate: cooldownClockDate,
                    cardCooldownEndDates: cardCooldownEndDates,
                    skillCooldownEndDates: skillCooldownEndDates,
                    onCardAttack: { card in
                        performCardAttack(
                            cardID: card.id,
                            cooldownSeconds: card.cooldownSeconds,
                            viewSize: viewSize
                        )
                    },
                    onSkillActivation: activateSkill
                )
                .padding(.bottom, cardBottomPadding)
                .padding(.horizontal, 14)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottom
                )
                .zIndex(12)

                if let transitionArea {
                    BattleTransitionView(
                        areaName: transitionArea.name,
                        imageName: transitionArea.transitionImageName
                    )
                    .zIndex(20)
                }

            }
            .frame(width: viewSize.width, height: viewSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .background(
            selectedBackgroundLook.backgroundColor.swiftUIColor
        )
        .ignoresSafeArea()
        .onAppear {
            selectedLookIndex = lookIndex
            previousAreaID = currentArea.id
            updateBattleCharacter()
            scene.updateEnemy(currentEnemy, isBoss: isBossStage)
            scene.updateShadowClone(animationID: activeShadowCloneAnimationID)
        }
        .onChange(of: lookIndex) { _, newLookIndex in
            selectedLookIndex = newLookIndex
        }
        .onChange(of: heroAnimationID) { _, animationID in
            updateBattleCharacter(heroAnimationID: animationID)
        }
        .onChange(of: equippedWeaponImageName) { _, imageName in
            updateBattleCharacter(equippedWeaponImageName: imageName)
        }
        .onChange(of: equippedWeaponBattleAppearance) { _, appearance in
            updateBattleCharacter(equippedWeaponBattleAppearance: appearance)
        }
        .onChange(of: currentEnemy.id) { _, _ in
            scene.updateEnemy(currentEnemy, isBoss: isBossStage)
        }
        .onChange(of: activeSkillIDs) { _, _ in
            scene.updateShadowClone(animationID: activeShadowCloneAnimationID)
        }
        .onChange(of: currentArea.id) { oldAreaID, newAreaID in
            guard oldAreaID != newAreaID else { return }
            showAreaTransition(currentArea)
        }
        .task {
            await runCooldownClock()
        }
    }

    private func updateBattleCharacter(
        heroAnimationID: String? = nil,
        equippedWeaponImageName: String? = nil,
        equippedWeaponBattleAppearance: WeaponBattleAppearance? = nil
    ) {
        scene.updateBattleCharacter(
            heroAnimationID: heroAnimationID ?? self.heroAnimationID,
            equippedWeaponImageName: equippedWeaponImageName
                ?? self.equippedWeaponImageName,
            equippedWeaponShadowCloneImageName: progress
                .equippedWeaponShadowCloneImageName,
            equippedWeaponBattleAppearance: equippedWeaponBattleAppearance
                ?? self.equippedWeaponBattleAppearance
        )
    }

    private func activateSkill(_ skill: BattleActiveSkill) {
        guard
            !activeSkillIDs.contains(skill.id),
            skillCooldownRemaining(for: skill.id) <= 0
        else {
            return
        }

        activeSkillIDs.insert(skill.id)
        addPopup(
            text: skill.title,
            color: .cyan,
            xRatio: 0.5,
            yRatio: 0.34,
            imageName: skill.imageName
        )

        Task {
            await runActiveSkill(skill)
        }
    }

    private func performCardAttack(
        cardID: String,
        cooldownSeconds: Double,
        viewSize: CGSize
    ) {
        guard cardCooldownRemaining(for: cardID) <= 0 else { return }

        if cooldownSeconds > 0 {
            coolingDownCardIDs.insert(cardID)
            cardCooldownEndDates[cardID] = Date().addingTimeInterval(
                cooldownSeconds
            )
        }
        let card = cardDefinition(for: cardID)
        scene.playHeroAttackAnimation(move: card?.move ?? .punch)
        if let card {
            performAttack(
                onBattleCardAttack?(card) ?? onTapAttack(),
                in: viewSize
            )
        } else {
            performAttack(onTapAttack(), in: viewSize)
        }
    }

    private func performTapAttack(in viewSize: CGSize) {
        let now = Date()
        guard
            now.timeIntervalSince(lastTapAttackDate)
                >= progress.tapCooldownSeconds
        else {
            return
        }

        lastTapAttackDate = now
        scene.playHeroAttackAnimation(move: .punch)
        performAttack(onTapAttack(), in: viewSize)
    }

    private func runActiveSkill(_ skill: BattleActiveSkill) async {
        let duration = max(skill.durationSeconds, 0.1)
        let interval = max(skill.tickIntervalSeconds, 0.15)
        let ticks = max(1, Int((duration / interval).rounded(.down)))

        for _ in 0..<ticks {
            try? await Task.sleep(nanoseconds: nanoseconds(for: interval))
            await MainActor.run {
                guard activeSkillIDs.contains(skill.id) else { return }
                performAttack(onActiveSkillAttack(skill))
            }
        }

        await MainActor.run {
            _ = activeSkillIDs.remove(skill.id)
            coolingDownSkillIDs.insert(skill.id)
            skillCooldownEndDates[skill.id] = Date().addingTimeInterval(
                max(skill.cooldownSeconds, 0)
            )
        }

        try? await Task.sleep(
            nanoseconds: nanoseconds(for: max(skill.cooldownSeconds, 0.1))
        )

        await MainActor.run {
            _ = coolingDownSkillIDs.remove(skill.id)
            skillCooldownEndDates[skill.id] = nil
        }
    }

    private func nanoseconds(for seconds: Double) -> UInt64 {
        UInt64(max(seconds, 0) * 1_000_000_000)
    }

    private func runCooldownClock() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))

            await MainActor.run {
                cooldownClockDate = Date()
                clearExpiredCooldowns()
            }
        }
    }

    private func clearExpiredCooldowns() {
        for (id, endDate) in cardCooldownEndDates
        where endDate <= cooldownClockDate {
            cardCooldownEndDates[id] = nil
            coolingDownCardIDs.remove(id)
        }

        for (id, endDate) in skillCooldownEndDates
        where endDate <= cooldownClockDate {
            skillCooldownEndDates[id] = nil
            coolingDownSkillIDs.remove(id)
        }
    }

    private func performAttack(
        _ result: BattleAttackResult,
        in viewSize: CGSize? = nil
    ) {
        guard result.damageDealt > 0 else { return }

        addPopup(
            text: result.isCriticalHit
                ? "CRIT -\(result.damageDealt)"
                : "-\(result.damageDealt)",
            color: result.isCriticalHit ? .yellow : .white,
            xRatio: Double.random(in: 0.34...0.66),
            yRatio: Double.random(in: 0.36...0.52)
        )

        if result.extraStagesCleared > 0 {
            addPopup(
                text: "+\(result.extraStagesCleared) Stages",
                color: .systemTeal,
                xRatio: 0.5,
                yRatio: 0.62,
                imageName: "icon_pixel_dimension_rift"
            )
        }

        if result.coinsAwarded > 0 {
            addRewardPopups(
                imageName: "icon_pixel_coin",
                count: min(max(result.coinsAwarded / 10, 3), 10),
                xRange: 0.22...0.78
            )
        }

        if result.crystalsAwarded > 0 {
            addRewardPopups(
                imageName: "icon_pixel_crystal",
                count: min(max(result.crystalsAwarded, 1), 6),
                xRange: 0.44...0.82
            )
            addPopup(
                text: "+\(result.crystalsAwarded)",
                color: .cyan,
                xRatio: 0.72,
                yRatio: 0.58,
                imageName: "icon_pixel_crystal"
            )
        }

        if result.relicsAwarded > 0 {
            addRewardPopups(
                imageName: "icon_pixel_relic",
                count: min(max(result.relicsAwarded, 1), 6),
                xRange: 0.18...0.56
            )
            addPopup(
                text: "+\(result.relicsAwarded)",
                color: .systemPurple,
                xRatio: 0.22,
                yRatio: 0.5,
                imageName: "icon_pixel_relic"
            )
        }

        if result.skillBooksAwarded > 0 {
            addRewardPopups(
                imageName: "icon_pixel_skill_book",
                count: min(max(result.skillBooksAwarded, 1), 6),
                xRange: 0.24...0.64
            )
            addPopup(
                text: "+\(result.skillBooksAwarded)",
                color: .systemMint,
                xRatio: 0.28,
                yRatio: 0.58,
                imageName: "icon_pixel_skill_book"
            )
        }

        if result.eventChipsAwarded > 0 {
            let imageName = result.eventChipImageName ?? "icon_pixel_chip_blue"
            addRewardPopups(
                imageName: imageName,
                count: min(max(result.eventChipsAwarded / 20, 3), 8),
                xRange: 0.22...0.78
            )
            addPopup(
                text: "+\(result.eventChipsAwarded)",
                color: .systemOrange,
                xRatio: 0.5,
                yRatio: 0.58,
                imageName: imageName
            )
        }
    }

    private func addRewardPopups(
        imageName: String,
        count: Int,
        xRange: ClosedRange<Double>
    ) {
        for index in 0..<count {
            Task {
                try? await Task.sleep(for: .milliseconds(index * 45))
                await MainActor.run {
                    addPopup(
                        text: "",
                        color: .yellow,
                        xRatio: Double.random(in: xRange),
                        yRatio: Double.random(in: 0.62...0.78),
                        imageName: imageName
                    )
                }
            }
        }
    }

    private func addPopup(
        text: String,
        color: UIColor,
        xRatio: Double,
        yRatio: Double,
        imageName: String? = nil
    ) {
        scene.showPopup(
            text: text,
            color: color,
            xRatio: xRatio,
            yRatio: yRatio,
            imageName: imageName
        )
    }

    private var backgroundLookIndex: Int {
        guard !background.looks.isEmpty else { return 0 }
        return min(max(selectedLookIndex, 0), background.looks.count - 1)
    }

    private var groundLookIndex: Int {
        guard !arena.looks.isEmpty else { return 0 }
        return min(max(selectedLookIndex, 0), arena.looks.count - 1)
    }

    private var selectedBackgroundLook: GameBackgroundLook {
        guard !background.looks.isEmpty else {
            return Self.fallbackBackgroundLook
        }

        return background.looks[backgroundLookIndex]
    }

    private var selectedGroundLook: ArenaLook {
        guard !arena.looks.isEmpty else {
            return Self.fallbackGroundLook
        }

        return arena.looks[groundLookIndex]
    }

    private static let fallbackBackgroundLook = GameBackgroundLook(
        name: "Fallback",
        backgroundColor: RGBColor(red: 0.03, green: 0.06, blue: 0.12),
        backgroundImageName: nil,
        backgroundDarkening: 0
    )

    private static let fallbackGroundLook = ArenaLook(
        name: "Fallback",
        groundImageName: nil,
        groundDarkening: 0
    )

    private var currentStage: Int {
        max(progress.stage, 1)
    }

    private var currentArea: EnemyArea {
        enemies.area(for: currentStage)
    }

    private var currentEnemy: EnemyDefinition {
        enemies.enemy(for: currentStage)
    }

    private var isBossStage: Bool {
        currentStage.isMultiple(of: 10)
    }

    private var activeShadowCloneAnimationID: String? {
        guard
            let skill = activeSkills.first(where: {
                activeSkillIDs.contains($0.id) && $0.kind == .shadowClone
            })
        else {
            return nil
        }

        return skill.companionAnimationID ?? heroAnimationID
    }

    private func showAreaTransition(_ area: EnemyArea) {
        transitionArea = area

        Task {
            try? await Task.sleep(for: .milliseconds(1150))
            await MainActor.run {
                guard transitionArea?.id == area.id else { return }
                transitionArea = nil
            }
        }
    }

    @ViewBuilder
    private func backgroundLayer(
        look: GameBackgroundLook,
        viewSize: CGSize
    ) -> some View {
        if let imageName = backgroundImageName ?? look.backgroundImageName {
            RemoteImage(name: imageName, contentMode: .fill)
                .frame(
                    width: viewSize.width,
                    height: viewSize.height
                )
                .clipped()
                .ignoresSafeArea()
        } else {
            look.backgroundColor.swiftUIColor
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func groundLayer(
        look: ArenaLook,
        viewSize: CGSize,
        groundHeight: CGFloat
    ) -> some View {
        if let imageName = groundImageName ?? look.groundImageName {
            RemoteImage(name: imageName, contentMode: .fill)
                .frame(
                    width: viewSize.width,
                    height: groundHeight
                )
                .clipped()
        } else {
            Color.black
                .frame(
                    width: viewSize.width,
                    height: groundHeight
                )
        }
    }

    @ViewBuilder
    private func backgroundDarkeningLayer(look: GameBackgroundLook) -> some View
    {
        let opacity = min(max(look.backgroundDarkening, 0), 1)

        if opacity > 0 {
            Color.black
                .opacity(opacity)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func groundDarkeningLayer(
        look: ArenaLook,
        groundHeight: CGFloat
    ) -> some View {
        let opacity = min(max(look.groundDarkening, 0), 1)

        if opacity > 0 {
            Rectangle()
                .fill(.black.opacity(opacity))
                .frame(height: groundHeight)
        }
    }

    private func exitButton(onExit: @escaping () -> Void) -> some View {
        Button {
            onExit()
        } label: {
            RemoteImage(name: "icon_pixel_house")
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func prestigeButton(onPrestige: @escaping () -> Void) -> some View {
        Button {
            onPrestige()
        } label: {
            VStack(spacing: 0) {
                RemoteImage(name: "icon_pixel_prestige")
                    .frame(width: 28, height: 28)

                Text("Prestige")
                    .widerwillenFont(size: 9, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }
            .frame(width: 62, height: 58)
            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func cardDefinition(for id: String) -> BattleCardDefinition? {
        battleCards.cards.first { $0.id == id }
    }

    private func cardCooldownRemaining(for id: String) -> TimeInterval {
        max(
            cardCooldownEndDates[id]?.timeIntervalSince(cooldownClockDate) ?? 0,
            0
        )
    }

    private func skillCooldownRemaining(for id: String) -> TimeInterval {
        max(
            skillCooldownEndDates[id]?.timeIntervalSince(cooldownClockDate)
                ?? 0,
            0
        )
    }

}

extension SpriteAnimationScene {
    static func makeDefaultScene(arena: ArenaConfiguration)
        -> SpriteAnimationScene
    {
        let scene = SpriteAnimationScene(
            size: CGSize(width: 400, height: 400),
            arena: arena
        )
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
}

#Preview {
    BattleSceneView(
        progress: GameProgressStore(),
        title: "Stage 1",
        healthTitle: "Raid HP",
        currentHP: 40,
        maxHP: 40,
        lookIndex: 0,
        heroAnimationID: "nimbi_original",
        equippedWeaponImageName: "icon_pixel_sword",
        onTapAttack: { BattleAttackResult(damageDealt: 1) },
        onExit: {}
    )
}
