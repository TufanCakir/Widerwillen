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
    let isAutoBattleEnabled: Bool
    let onAttack: () -> Void
    let onExit: (() -> Void)?

    private let arena: ArenaConfiguration
    private let background: BackgroundConfiguration

    @State private var scene: SpriteAnimationScene
    @State private var selectedLookIndex: Int
    @State private var animationStartDate = Date()
    @AppStorage("isLayerAnimationEnabled") private var isLayerAnimationEnabled =
        true

    private let animationFrameInterval = 1.0 / 30.0
    private let autoBattleInterval: Duration = .seconds(1.4)

    init(
        progress: GameProgressStore,
        title: String,
        healthTitle: String,
        currentHP: Int,
        maxHP: Int,
        lookIndex: Int,
        isAutoBattleEnabled: Bool,
        onAttack: @escaping () -> Void,
        onExit: (() -> Void)? = nil,
        arena: ArenaConfiguration = try! ArenaConfiguration.load(),
        background: BackgroundConfiguration =
            try! BackgroundConfiguration.load()
    ) {
        self.progress = progress
        self.title = title
        self.healthTitle = healthTitle
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.lookIndex = lookIndex
        self.isAutoBattleEnabled = isAutoBattleEnabled
        self.onAttack = onAttack
        self.onExit = onExit
        self.arena = arena
        self.background = background
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

                headerHUD
                    .padding(.horizontal)
                    .padding(.top, 54)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .top
                    )

                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
                    .padding(.top, 150)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .top
                    )

                if let onExit {
                    exitButton(onExit: onExit)
                        .padding(.top, 158)
                        .padding(.trailing, 18)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topTrailing
                        )
                }

            }
            .frame(width: viewSize.width, height: viewSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            background.looks[backgroundLookIndex].backgroundColor.swiftUIColor
        )
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            onAttack()
        }
        .onAppear {
            selectedLookIndex = lookIndex
            scene.updateUnlockedSpriteIndices(progress.unlockedSpriteIndices)
        }
        .onChange(of: lookIndex) { _, newLookIndex in
            selectedLookIndex = newLookIndex
        }
        .onChange(of: progress.unlockedSpriteIndices) { _, indices in
            scene.updateUnlockedSpriteIndices(indices)
        }
        .task {
            await runAutoBattleLoop()
        }
    }

    private func runAutoBattleLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: autoBattleInterval)

            guard isAutoBattleEnabled else { continue }

            await MainActor.run {
                onAttack()
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

    private var headerHUD: some View {
        VStack(spacing: 20) {
            GameHeader(progress: progress)

            healthBar
                .padding(.horizontal, 50)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
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
    }

    @ViewBuilder
    private func backgroundLayer(
        look: GameBackgroundLook,
        viewSize: CGSize
    ) -> some View {
        if let backgroundImageName = look.backgroundImageName {
            Image(backgroundImageName)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
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
            Image(groundImageName)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
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
            Image("icon_pixel_house")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
        isAutoBattleEnabled: true,
        onAttack: {},
        onExit: {}
    )
}
