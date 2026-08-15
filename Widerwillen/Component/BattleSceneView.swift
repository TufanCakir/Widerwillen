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
    let onTapAttack: () -> BattleAttackResult
    let onSpriteAttack: () -> BattleAttackResult
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
        onTapAttack: @escaping () -> BattleAttackResult,
        onSpriteAttack: @escaping () -> BattleAttackResult,
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
        self.onTapAttack = onTapAttack
        self.onSpriteAttack = onSpriteAttack
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
                        .padding(.bottom, 118)
                        .padding(.horizontal, 34)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottom
                        )
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
                imageName: "icon_pixel_skill_books"
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

    private func enemyLayer(viewSize: CGSize, groundHeight: CGFloat) -> some View {
        let enemySize = min(viewSize.width, viewSize.height)
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
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: battlePopups.count)
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
            HStack(spacing: 10) {
                RemoteImage(name: "icon_pixel_relic")
                    .frame(width: 24, height: 24)

                Text("Prestige")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.black.opacity(0.62))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.78), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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
