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
    let companionAnimationIDs: Set<String>
    let spriteAttackInterval: Duration
    let activeSkills: [BattleActiveSkill]
    let backgroundImageName: String?
    let groundImageName: String?
    let onTapAttack: () -> BattleAttackResult
    let onBattleCardAttack: ((BattleCardDefinition) -> BattleAttackResult)?
    let onSpriteAttack: () -> BattleAttackResult
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
    @State private var battlePopups: [BattlePopup] = []
    @State private var previousAreaID: String?
    @State private var transitionArea: EnemyArea?
    @State private var activeSkillIDs: Set<String> = []
    @State private var coolingDownSkillIDs: Set<String> = []
    @State private var coolingDownCardIDs: Set<String> = []
    @State private var cardCooldownEndDates: [String: Date] = [:]
    @State private var skillCooldownEndDates: [String: Date] = [:]
    @State private var cooldownClockDate = Date()
    @AppStorage("isLayerAnimationEnabled") private var isLayerAnimationEnabled =
        true

    private let maxBattlePopupCount = 16

    init(
        progress: GameProgressStore,
        title: String,
        healthTitle: String,
        currentHP: Int,
        maxHP: Int,
        lookIndex: Int,
        heroAnimationID: String,
        companionAnimationIDs: Set<String>,
        spriteAttackInterval: Duration,
        activeSkills: [BattleActiveSkill] = [],
        backgroundImageName: String? = nil,
        groundImageName: String? = nil,
        onTapAttack: @escaping () -> BattleAttackResult,
        onBattleCardAttack: ((BattleCardDefinition) -> BattleAttackResult)? = nil,
        onSpriteAttack: @escaping () -> BattleAttackResult,
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
        self.companionAnimationIDs = companionAnimationIDs
        self.spriteAttackInterval = spriteAttackInterval
        self.activeSkills = activeSkills
        self.backgroundImageName = backgroundImageName
        self.groundImageName = groundImageName
        self.onTapAttack = onTapAttack
        self.onBattleCardAttack = onBattleCardAttack
        self.onSpriteAttack = onSpriteAttack
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
            let backgroundLook = background.looks[backgroundLookIndex]
            let groundLook = arena.looks[groundLookIndex]

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

                enemyLayer(viewSize: viewSize, groundHeight: groundHeight)

                activeSkillVisualLayer(
                    viewSize: viewSize,
                    groundHeight: groundHeight
                )

                popupLayer(viewSize: viewSize)

                headerHUD
                    .padding(.horizontal)
                    .padding(.top, 54)
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
                .padding(.top, 250)
                .padding(.trailing, 18)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topTrailing
                )
                .zIndex(12)

                battleCardBar(viewSize: viewSize)
                    .padding(.bottom, 24)
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
            background.looks[backgroundLookIndex].backgroundColor.swiftUIColor
        )
        .ignoresSafeArea()
        .onAppear {
            selectedLookIndex = lookIndex
            previousAreaID = currentArea.id
            scene.updateBattleSprites(
                heroAnimationID: heroAnimationID,
                companionAnimationIDs: companionAnimationIDs
            )
        }
        .onChange(of: lookIndex) { _, newLookIndex in
            selectedLookIndex = newLookIndex
        }
        .onChange(of: heroAnimationID) { _, animationID in
            scene.updateBattleSprites(
                heroAnimationID: animationID,
                companionAnimationIDs: companionAnimationIDs
            )
        }
        .onChange(of: companionAnimationIDs) { _, animationIDs in
            scene.updateBattleSprites(
                heroAnimationID: heroAnimationID,
                companionAnimationIDs: animationIDs
            )
        }
        .onChange(of: currentArea.id) { oldAreaID, newAreaID in
            guard oldAreaID != newAreaID else { return }
            showAreaTransition(currentArea)
        }
        .task {
            await runSpriteAttackLoop()
        }
        .task {
            await runCooldownClock()
        }
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
            performAttack(onBattleCardAttack?(card) ?? onTapAttack(), in: viewSize)
        } else {
            performAttack(onTapAttack(), in: viewSize)
        }
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

    private func runSpriteAttackLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: spriteAttackInterval)

            await MainActor.run {
                performAttack(onSpriteAttack())
            }
        }
    }

    private func runCooldownClock() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(160))

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
            text: "-\(result.damageDealt)",
            color: .white,
            xRatio: Double.random(in: 0.34...0.66),
            yRatio: Double.random(in: 0.36...0.52)
        )

        if result.coinsAwarded > 0 {
            addCoinPopups(count: min(max(result.coinsAwarded / 10, 3), 10))
        }

        if result.crystalsAwarded > 0 {
            addPopup(
                text: "+\(result.crystalsAwarded)",
                color: .cyan,
                xRatio: 0.72,
                yRatio: 0.58,
                imageName: "icon_pixel_crystal"
            )
        }

        if result.skillBooksAwarded > 0 {
            addPopup(
                text: "+\(result.skillBooksAwarded)",
                color: .mint,
                xRatio: 0.28,
                yRatio: 0.58,
                imageName: "icon_pixel_skill_book"
            )
        }
    }

    private func addCoinPopups(count: Int) {
        for index in 0..<count {
            Task {
                try? await Task.sleep(for: .milliseconds(index * 45))
                await MainActor.run {
                    addPopup(
                        text: "",
                        color: .yellow,
                        xRatio: Double.random(in: 0.22...0.78),
                        yRatio: Double.random(in: 0.62...0.78),
                        imageName: "icon_pixel_coin"
                    )
                }
            }
        }
    }

    private func addPopup(
        text: String,
        color: Color,
        xRatio: Double,
        yRatio: Double,
        imageName: String? = nil
    ) {
        let popup = BattlePopup(
            text: text,
            color: color,
            xRatio: xRatio,
            yRatio: yRatio,
            imageName: imageName
        )
        battlePopups.append(popup)
        if battlePopups.count > maxBattlePopupCount {
            battlePopups.removeFirst(battlePopups.count - maxBattlePopupCount)
        }

        Task {
            try? await Task.sleep(for: .milliseconds(850))
            await MainActor.run {
                battlePopups.removeAll { $0.id == popup.id }
            }
        }
    }

    private var backgroundLookIndex: Int {
        guard !background.looks.isEmpty else { return 0 }
        return min(max(selectedLookIndex, 0), background.looks.count - 1)
    }

    private var groundLookIndex: Int {
        guard !arena.looks.isEmpty else { return 0 }
        return min(max(selectedLookIndex, 0), arena.looks.count - 1)
    }

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

    private func enemyLayer(viewSize: CGSize, groundHeight: CGFloat)
        -> some View
    {
        let enemySize =
            min(viewSize.width, viewSize.height)
            * CGFloat(currentEnemy.scale)
        let baselineY = battleBaselineY(
            viewSize: viewSize,
            groundHeight: groundHeight
        )

        return VStack(spacing: 4) {
            Text(
                isBossStage ? "Boss · \(currentEnemy.name)" : currentEnemy.name
            )
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(isBossStage ? .red : .white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

            SpriteSheetImageView(
                animationID: currentEnemy.animationID ?? currentEnemy.imageName,
                columns: currentEnemy.columns,
                rows: currentEnemy.rows,
                frameCount: currentEnemy.frameCount,
                fps: currentEnemy.fps
            )
            .frame(
                width: enemySize,
                height: enemySize
            )
            .scaleEffect(x: -1, y: 1)
            .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)
        }
        .position(
            x: viewSize.width * 0.66,
            y: baselineY - enemySize * 0.5
        )
        .allowsHitTesting(false)
    }

    private func battleBaselineY(viewSize: CGSize, groundHeight: CGFloat)
        -> CGFloat
    {
        viewSize.height - groundHeight * 0.56
    }

    private func activeSkillVisualLayer(
        viewSize: CGSize,
        groundHeight: CGFloat
    ) -> some View {
        ZStack {
            ForEach(activeSkills.filter { activeSkillIDs.contains($0.id) }) {
                skill in
                if skill.kind == .shadowClone {
                    let cloneSize = min(viewSize.width, viewSize.height) * 0.26
                    let baselineY = battleBaselineY(
                        viewSize: viewSize,
                        groundHeight: groundHeight
                    )

                    SpriteSheetImageView(
                        animationID: skill.companionAnimationID
                            ?? heroAnimationID,
                        columns: 3,
                        rows: 1,
                        frameCount: 3,
                        fps: 8
                    )
                    .frame(width: cloneSize, height: cloneSize)
                    .opacity(0.62)
                    .scaleEffect(x: -1, y: 1)
                    .shadow(color: .cyan.opacity(0.8), radius: 8, x: 0, y: 0)
                    .position(
                        x: viewSize.width * 0.44,
                        y: baselineY - cloneSize * 0.5
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: activeSkillIDs)
        .allowsHitTesting(false)
    }

    private var headerHUD: some View {
        VStack(spacing: 14) {
            GameHeader(progress: progress)

            combatStatus
        }
    }

    private var combatStatus: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            healthBar
        }
        .padding(.horizontal, 52)
        .frame(maxWidth: .infinity)
    }

    private var healthBar: some View {
        VStack(spacing: 5) {
            GeometryReader { proxy in
                let ratio = CGFloat(currentHP) / CGFloat(max(maxHP, 1))

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.black.opacity(0.58))

                    Rectangle()
                        .fill(.red)
                        .frame(width: proxy.size.width * min(max(ratio, 0), 1))
                }
            }
            .frame(height: 14)
            .overlay {
                Rectangle()
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }

            HStack {
                Text(healthTitle)
                Spacer()
                Text("\(currentHP)/\(maxHP)")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func popupLayer(viewSize: CGSize) -> some View {
        ZStack {
            ForEach(battlePopups) { popup in
                VStack(spacing: 3) {
                    if let imageName = popup.imageName {
                        RemoteImage(name: imageName)
                            .frame(width: 28, height: 28)
                    }

                    if !popup.text.isEmpty {
                        Text(popup.text)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(popup.color)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                    }
                }
                .position(
                    x: viewSize.width * popup.xRatio,
                    y: viewSize.height * popup.yRatio
                )
                .transition(
                    .asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
            }
        }
        .animation(
            .spring(response: 0.28, dampingFraction: 0.7),
            value: battlePopups.count
        )
        .allowsHitTesting(false)
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
                    .font(.system(size: 9, weight: .heavy))
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

    private func battleCardBar(viewSize: CGSize) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(unlockedBattleCards) { card in
                    battleCardButton(
                        card: card,
                        cooldownRemaining: cardCooldownRemaining(for: card.id),
                        isActive: false
                    ) {
                        performCardAttack(
                            cardID: card.id,
                            cooldownSeconds: card.cooldownSeconds,
                            viewSize: viewSize
                        )
                    }
                }

                ForEach(activeSkills) { skill in
                    let card = cardDefinition(for: skill.id)
                    let isActive = activeSkillIDs.contains(skill.id)

                    battleCardButton(
                        card: card,
                        fallbackTitle: skill.title,
                        fallbackImageName: skill.imageName,
                        cooldownRemaining: skillCooldownRemaining(for: skill.id),
                        isActive: isActive
                    ) {
                        activateSkill(skill)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
    }

    private func battleCardButton(
        card: BattleCardDefinition?,
        fallbackTitle: String = "Tab",
        fallbackImageName: String = "icon_pixel_sword",
        cooldownRemaining: TimeInterval,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let title = card?.title ?? fallbackTitle
        let imageName = card?.imageName ?? fallbackImageName
        let backgroundImageName = card?.backgroundImageName
        let gradientColors = card?.gradientColors ?? []
        let move = card?.move ?? .punch
        let style = card?.style ?? "Strike"
        let staminaCost = card?.staminaCost ?? 0
        let damageMultiplier = card?.damageMultiplier ?? 1
        let isCoolingDown = cooldownRemaining > 0

        return Button(action: action) {
            ZStack {
                if let cardImageName = card?.cardImageName {
                    RemoteImage(name: cardImageName, contentMode: .fill)
                        .frame(width: 142, height: 138)
                        .clipped()
                } else if let backgroundImageName {
                    RemoteImage(name: backgroundImageName, contentMode: .fill)
                        .frame(width: 142, height: 138)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: colors(from: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Spacer(minLength: 4)

                        Text(style)
                            .font(.system(size: 9, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(.white.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }

                    BattleCardMovePreview(move: move, fallbackImageName: imageName)
                        .frame(width: 80, height: 64)
                        .clipped()

                    HStack(spacing: 8) {
                        Text("DMG x\(damageText(damageMultiplier))")
                        Text("STA \(staminaCost)")
                    }
                    .font(.system(size: 10, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 1)

                if isCoolingDown {
                    Color.black.opacity(0.64)

                    VStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .heavy))

                        Text("\(Int(ceil(cooldownRemaining)))s")
                            .font(.system(size: 15, weight: .heavy))
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 1)
                }
            }
            .frame(width: 142, height: 138)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isActive ? .cyan : .white.opacity(0.7),
                        lineWidth: isActive ? 3 : 1
                    )
            }
            .shadow(color: .black.opacity(0.82), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isCoolingDown || isActive)
        .opacity(isCoolingDown ? 0.68 : 1)
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
            skillCooldownEndDates[id]?.timeIntervalSince(cooldownClockDate) ?? 0,
            0
        )
    }

    private var unlockedBattleCards: [BattleCardDefinition] {
        battleCards.cards.filter { card in
            guard card.id != "shadow_clone_active" else { return false }
            guard let skillID = card.requiredSkillID else { return true }

            return progress.skillLevel(forSkillID: skillID)
                >= card.requiredSkillLevel
        }
    }

    private func damageText(_ multiplier: Double) -> String {
        if multiplier.rounded() == multiplier {
            return "\(Int(multiplier))"
        }

        return String(format: "%.1f", multiplier)
    }

    @MainActor
    private func colors(from hexValues: [String]) -> [Color] {
        let colors = hexValues.map(Color.init(hex:))
        return colors.isEmpty ? [.white, .cyan] : colors
    }

    private struct BattleCardMovePreview: View {
        let move: BattleCardMove
        let fallbackImageName: String

        var body: some View {
            ZStack {
                part("sprite_nimbi_original_left_foot", z: 0)
                    .offset(pose.leftFootOffset)
                    .rotationEffect(pose.leftFootRotation)

                part("sprite_nimbi_original_right_foot", z: 1)
                    .offset(pose.rightFootOffset)
                    .rotationEffect(pose.rightFootRotation)

                part("sprite_nimbi_original_body", z: 2)
                    .rotationEffect(pose.bodyRotation)

                part("sprite_nimbi_original_left_hand", z: 3)
                    .offset(pose.leftHandOffset)
                    .rotationEffect(pose.leftHandRotation)

                part("sprite_nimbi_original_right_hand", z: 4)
                    .offset(pose.rightHandOffset)
                    .rotationEffect(pose.rightHandRotation)

                part("sprite_original_slenderize_sword", z: 5, size: 16)
                    .offset(pose.weaponOffset)
                    .rotationEffect(pose.weaponRotation)

                part("sprite_nimbi_original_head", z: 6)
                    .offset(pose.headOffset)
                    .rotationEffect(pose.headRotation)
            }
            .scaleEffect(pose.scale)
            .rotationEffect(pose.characterRotation)
            .offset(pose.characterOffset)
        }

        private func part(
            _ imageName: String,
            z: Double,
            size: CGFloat = 32
        ) -> some View {
            RemoteImage(
                name: imageName,
                placeholderColor: .white.opacity(0.14),
                fallbackSystemImage: fallbackImageName
            )
            .frame(width: size, height: size)
            .zIndex(z)
        }

        private var pose: BattleCardPreviewPose {
            BattleCardPreviewPose(move: move)
        }
    }

    private struct BattleCardPreviewPose {
        var scale: CGFloat = 1.7
        var characterOffset = CGSize.zero
        var characterRotation = Angle.zero
        var bodyRotation = Angle.zero
        var headOffset = CGSize.zero
        var headRotation = Angle.zero
        var leftHandOffset = CGSize.zero
        var leftHandRotation = Angle.zero
        var rightHandOffset = CGSize.zero
        var rightHandRotation = Angle.zero
        var weaponOffset = CGSize(width: 9, height: -2)
        var weaponRotation = Angle.degrees(-18)
        var leftFootOffset = CGSize.zero
        var leftFootRotation = Angle.zero
        var rightFootOffset = CGSize.zero
        var rightFootRotation = Angle.zero

        init(move: BattleCardMove) {
            switch move {
            case .punch:
                rightHandOffset = CGSize(width: 11, height: -2)
                rightHandRotation = .degrees(-28)
                leftHandOffset = CGSize(width: -2, height: -3)
                leftHandRotation = .degrees(16)
                weaponOffset = CGSize(width: 15, height: -4)
                weaponRotation = .degrees(-38)
                bodyRotation = .degrees(-5)
            case .kick:
                rightFootOffset = CGSize(width: 12, height: 5)
                rightFootRotation = .degrees(-24)
                leftFootOffset = CGSize(width: -2, height: 1)
                bodyRotation = .degrees(4)
            case .dash:
                characterOffset = CGSize(width: 9, height: -1)
                scale = 1.6
                rightHandOffset = CGSize(width: 4, height: 0)
                weaponOffset = CGSize(width: 11, height: -2)
                weaponRotation = .degrees(-32)
                bodyRotation = .degrees(-8)
            case .tornado:
                characterOffset = CGSize(width: 2, height: -4)
                characterRotation = .degrees(28)
                weaponOffset = CGSize(width: 8, height: -2)
                weaponRotation = .degrees(-60)
                rightFootOffset = CGSize(width: 12, height: 7)
                rightFootRotation = .degrees(-54)
                leftFootRotation = .degrees(24)
            case .roundhouse:
                rightFootOffset = CGSize(width: 14, height: 5)
                rightFootRotation = .degrees(-64)
                leftHandRotation = .degrees(24)
                weaponOffset = CGSize(width: 8, height: -1)
                weaponRotation = .degrees(12)
                bodyRotation = .degrees(10)
            case .airSpin:
                characterOffset = CGSize(width: 0, height: -5)
                characterRotation = .degrees(180)
                rightHandRotation = .degrees(-28)
                weaponOffset = CGSize(width: 7, height: -1)
                weaponRotation = .degrees(-54)
                leftHandRotation = .degrees(28)
                rightFootRotation = .degrees(-24)
                leftFootRotation = .degrees(24)
            }
        }
    }

    private struct BattlePopup: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
        let xRatio: Double
        let yRatio: Double
        let imageName: String?
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

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255

        self.init(red: red, green: green, blue: blue)
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
        heroAnimationID: "sprite_nimbi",
        companionAnimationIDs: [],
        spriteAttackInterval: .seconds(1.4),
        onTapAttack: { BattleAttackResult(damageDealt: 1) },
        onSpriteAttack: { BattleAttackResult(damageDealt: 1) },
        onExit: {}
    )
}
