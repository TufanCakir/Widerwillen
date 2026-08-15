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
    let onTapAttack: () -> BattleAttackResult
    let onSpriteAttack: () -> BattleAttackResult
    let onActiveSkillAttack: (BattleActiveSkill) -> BattleAttackResult
    let onPrestige: (() -> Void)?
    let onExit: (() -> Void)?

    private let arena: ArenaConfiguration
    private let background: BackgroundConfiguration
    private let enemies: EnemyConfiguration

    @State private var scene: SpriteAnimationScene
    @State private var selectedLookIndex: Int
    @State private var animationStartDate = Date()
    @State private var battlePopups: [BattlePopup] = []
    @State private var previousAreaID: String?
    @State private var transitionArea: EnemyArea?
    @State private var activeSkillIDs: Set<String> = []
    @State private var coolingDownSkillIDs: Set<String> = []
    @AppStorage("isLayerAnimationEnabled") private var isLayerAnimationEnabled =
        true

    private let animationFrameInterval = 1.0 / 30.0

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
        onTapAttack: @escaping () -> BattleAttackResult,
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
            (try? EnemyConfiguration.load()) ?? EnemyConfiguration(areas: [])
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
        self.onTapAttack = onTapAttack
        self.onSpriteAttack = onSpriteAttack
        self.onActiveSkillAttack = onActiveSkillAttack
        self.onPrestige = onPrestige
        self.onExit = onExit
        self.arena = arena
        self.background = background
        self.enemies = enemies
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

                if let onExit {
                    exitButton(onExit: onExit)
                        .padding(.top, 142)
                        .padding(.trailing, 18)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topTrailing
                        )
                }

                if let onPrestige, progress.canPrestige {
                    prestigeButton(onPrestige: onPrestige)
                        .padding(.top, onExit == nil ? 142 : 198)
                        .padding(.trailing, 18)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topTrailing
                        )
                        .zIndex(12)
                }

                if !activeSkills.isEmpty {
                    activeSkillBar
                        .padding(.bottom, 26)
                        .padding(.horizontal, 18)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottom
                        )
                        .zIndex(12)
                }

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
            .onTapGesture {
                scene.playHeroAttackAnimation()
                performAttack(onTapAttack(), in: viewSize)
            }
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
    }

    private func activateSkill(_ skill: BattleActiveSkill) {
        guard
            !activeSkillIDs.contains(skill.id),
            !coolingDownSkillIDs.contains(skill.id)
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
        }

        try? await Task.sleep(
            nanoseconds: nanoseconds(for: max(skill.cooldownSeconds, 0.1))
        )

        await MainActor.run {
            _ = coolingDownSkillIDs.remove(skill.id)
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

        return VStack(spacing: 4) {
            if isBossStage {
                Text("Boss")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.red)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }

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
            .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)
        }
        .position(
            x: viewSize.width * 0.62,
            y: viewSize.height - groundHeight * 0.12 - enemySize * 0.5
        )
        .allowsHitTesting(false)
    }

    private func activeSkillVisualLayer(
        viewSize: CGSize,
        groundHeight: CGFloat
    ) -> some View {
        ZStack {
            ForEach(activeSkills.filter { activeSkillIDs.contains($0.id) }) {
                skill in
                if skill.kind == .shadowClone {
                    SpriteSheetImageView(
                        animationID: skill.companionAnimationID
                            ?? heroAnimationID
                    )
                    .frame(width: 118, height: 118)
                    .opacity(0.46)
                    .scaleEffect(x: -1, y: 1)
                    .shadow(color: .cyan.opacity(0.8), radius: 8, x: 0, y: 0)
                    .position(
                        x: viewSize.width * 0.34,
                        y: viewSize.height - groundHeight * 0.14 - 58
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
        if let backgroundImageName = look.backgroundImageName {
            RemoteImage(name: backgroundImageName, contentMode: .fill)
                .frame(width: viewSize.width, height: viewSize.height)
                .clipped()
                .ignoresSafeArea()
        } else {
            TimelineView(
                .periodic(from: animationStartDate, by: animationFrameInterval)
            ) {
                timeline in
                let time =
                    isLayerAnimationEnabled && look.isAnimated
                    ? Float(timeline.date.timeIntervalSince(animationStartDate))
                        * Float(look.animationSpeed)
                    : 0

                Rectangle()
                    .fill(
                        ShaderLibrary.staticArenaBackground(
                            .float2(
                                Float(viewSize.width),
                                Float(viewSize.height)
                            ),
                            .float(time),
                            .float(Float(look.glowIntensity)),
                            .float(Float(look.accentColor.red)),
                            .float(Float(look.accentColor.green)),
                            .float(Float(look.accentColor.blue))
                        )
                    )
                    .ignoresSafeArea()
            }
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
    private func groundLayer(
        look: ArenaLook,
        viewSize: CGSize,
        groundHeight: CGFloat
    ) -> some View {
        if let groundImageName = look.groundImageName {
            RemoteImage(name: groundImageName, contentMode: .fill)
                .frame(width: viewSize.width, height: groundHeight)
                .clipped()
        } else {
            TimelineView(
                .periodic(from: animationStartDate, by: animationFrameInterval)
            ) {
                timeline in
                let time =
                    isLayerAnimationEnabled && look.isAnimated
                    ? Float(timeline.date.timeIntervalSince(animationStartDate))
                    : 0

                Rectangle()
                    .fill(
                        ShaderLibrary.riverFloor(
                            .float2(
                                Float(viewSize.width),
                                Float(groundHeight)
                            ),
                            .float(time),
                            .float(Float(look.animationSpeed)),
                            .float(Float(look.glowIntensity)),
                            .float(Float(look.gridIntensity)),
                            .float(Float(look.scanlineIntensity)),
                            .float(Float(look.accentColor.red)),
                            .float(Float(look.accentColor.green)),
                            .float(Float(look.accentColor.blue))
                        )
                    )
                    .frame(height: groundHeight)
            }
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
            VStack(spacing: 4) {
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
            .background(.black.opacity(0.58))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var activeSkillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(activeSkills) { skill in
                    activeSkillButton(skill)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.48))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
    }

    private func activeSkillButton(_ skill: BattleActiveSkill) -> some View {
        let isActive = activeSkillIDs.contains(skill.id)
        let isCoolingDown = coolingDownSkillIDs.contains(skill.id)

        return Button {
            activateSkill(skill)
        } label: {
            ZStack {
                Circle()
                    .fill(isActive ? .cyan.opacity(0.34) : .black.opacity(0.54))

                RemoteImage(name: skill.imageName)
                    .frame(width: 32, height: 32)

                if isCoolingDown {
                    Circle()
                        .fill(.black.opacity(0.62))

                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 54, height: 54)
            .overlay {
                Circle()
                    .stroke(
                        isActive ? .cyan : .white.opacity(0.72),
                        lineWidth: isActive ? 3 : 2
                    )
            }
            .shadow(color: .black.opacity(0.85), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isActive || isCoolingDown)
        .opacity(isCoolingDown ? 0.68 : 1)
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
