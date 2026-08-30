//
//  ShowcaseView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 30.08.26.
//

import SpriteKit
import SwiftUI
import UIKit

struct ShowcaseView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void
    let onExit: (() -> Void)?

    @State private var scene: SpriteAnimationScene
    @State private var selectedMove: BattleCardMove = .bladeStorm
    @State private var exportStatus = ""
    @State private var isExporting = false
    @State private var lastExportURL: URL?
    @State private var activeSkillIDs: Set<String> = []
    @State private var isLooping = true
    @State private var isCleanMode = false

    private let arena: ArenaConfiguration
    private let battleCards: BattleCardConfiguration

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void,
        onExit: (() -> Void)? = nil,
        arena: ArenaConfiguration = (try? ArenaConfiguration.load())
            ?? ArenaConfiguration(
                floorHeightRatio: 0.30,
                characterDepth: 1,
                characterScale: 1,
                characterXPosition: 0.5,
                looks: []
            ),
        battleCards: BattleCardConfiguration =
            (try? BattleCardConfiguration.load())
            ?? BattleCardConfiguration(cards: [])
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.onExit = onExit
        self.arena = arena
        self.battleCards = battleCards
        _scene = State(
            initialValue: SpriteAnimationScene(
                size: UIScreen.main.bounds.size,
                arena: arena
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CinematicShowcaseBackground()
                    .ignoresSafeArea()

                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .allowsHitTesting(false)
                .offset(y: 200)

                if !isCleanMode {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, max(proxy.safeAreaInsets.top, 14))
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .top
                        )
                        .transition(.opacity)
                }

                if !isCleanMode {
                    VStack(spacing: 10) {
                        BattleCardBar(
                            progress: progress,
                            battleCards: battleCards,
                            activeSkills: progress.activeBattleSkills,
                            activeSkillIDs: activeSkillIDs,
                            cooldownClockDate: Date(),
                            cardCooldownEndDates: [:],
                            skillCooldownEndDates: [:],
                            onCardAttack: playCard,
                            onSkillActivation: playSkill
                        )
                        .scaleEffect(0.82, anchor: .bottom)

                        exportControls
                    }
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard isCleanMode else { return }
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCleanMode = false
                }
            }
            .onAppear {
                configureScene(size: proxy.size)
                scene.playHeroAttackAnimation(move: selectedMove)
            }
            .onChange(of: proxy.size) { _, newSize in
                configureScene(size: newSize)
            }
            .onChange(of: progress.battleHeroAnimationID) { _, _ in
                configureScene(size: proxy.size)
            }
            .onChange(of: progress.equippedWeaponImageName) { _, _ in
                configureScene(size: proxy.size)
            }
            .task(id: "\(isLooping)-\(selectedMove.rawValue)") {
                await runSelectedMoveLoop()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            if let onExit {
                Button {
                    playSoundEffect("ui_back")
                    onExit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .heavy))
                        .frame(width: 38, height: 38)
                        .background(.black.opacity(0.42))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                playSoundEffect("ui_select")
                isLooping.toggle()
            } label: {
                Image(
                    systemName: isLooping
                        ? "repeat.circle.fill" : "repeat.circle"
                )
                .font(.system(size: 21, weight: .heavy))
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.42))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                playSoundEffect("ui_confirm")
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCleanMode = true
                }
            } label: {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.42))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }

    private var exportControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    Task { await captureSnapshot() }
                } label: {
                    Label("Camera Snapshot", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.system(size: 14, weight: .heavy))
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
            .disabled(isExporting)

            if let lastExportURL {
                ShareLink(item: lastExportURL) {
                    Label("Share snapshot", systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .heavy))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }

            if !exportStatus.isEmpty {
                Text(exportStatus)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(.white)
    }

    private func configureScene(size: CGSize) {
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.updateBattleSprites(
            heroAnimationID: progress.battleHeroAnimationID,
            equippedWeaponImageName: progress.equippedWeaponImageName,
            equippedWeaponBattleAppearance: progress
                .equippedWeaponBattleAppearance,
            companionAnimationIDs: []
        )
        scene.updateShowcaseLayout(
            heroXRatio: 0.5,
            heroYRatio: 1.28,
            heroScale: 0.34
        )
        scene.updateShadowClone(animationID: activeShadowCloneAnimationID)
    }

    private func playCard(_ card: BattleCardDefinition) {
        playSoundEffect("attack_manual")
        selectedMove = card.move
        scene.playHeroAttackAnimation(move: card.move)
    }

    private func runSelectedMoveLoop() async {
        guard isLooping else { return }

        while !Task.isCancelled {
            await MainActor.run {
                scene.playHeroAttackAnimation(move: selectedMove)
            }
            try? await Task.sleep(for: .milliseconds(1350))
        }
    }

    private func playSkill(_ skill: BattleActiveSkill) {
        playSoundEffect("ui_confirm")
        activeSkillIDs.insert(skill.id)
        scene.updateShadowClone(
            animationID: skill.companionAnimationID
                ?? progress.battleHeroAnimationID
        )

        Task {
            try? await Task.sleep(for: .milliseconds(3200))
            await MainActor.run {
                activeSkillIDs.remove(skill.id)
                scene.updateShadowClone(
                    animationID: activeShadowCloneAnimationID
                )
            }
        }
    }

    private var activeShadowCloneAnimationID: String? {
        progress.activeBattleSkills.first {
            activeSkillIDs.contains($0.id) && $0.kind == .shadowClone
        }?.companionAnimationID
    }

    private func captureSnapshot() async {
        guard !isExporting else { return }

        isExporting = true
        exportStatus = "Capturing snapshot..."
        defer { isExporting = false }

        do {
            let wasCleanMode = isCleanMode
            withAnimation(.easeInOut(duration: 0.12)) {
                isCleanMode = true
            }
            try await Task.sleep(for: .milliseconds(180))

            let image = try snapshotCurrentScreen()
            let url = FileManager.default.temporaryDirectory
                .appending(path: "widerwillen-showcase-snapshot.png")
            guard let data = image.pngData() else {
                throw ShowcaseExportError.renderFailed
            }
            try data.write(to: url, options: .atomic)

            lastExportURL = url
            exportStatus = "Snapshot ready."
            if !wasCleanMode {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isCleanMode = false
                }
            }
            playSoundEffect("ui_confirm")
        } catch {
            exportStatus = "Snapshot failed"
            withAnimation(.easeInOut(duration: 0.12)) {
                isCleanMode = false
            }
            playSoundEffect("ui_back")
            print("[ShowcaseView] snapshot failed: \(error)")
        }
    }

    @MainActor
    private func snapshotCurrentScreen() throws -> UIImage {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
                ?? windowScene.windows.first
        else {
            throw ShowcaseExportError.renderFailed
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

}

private struct CinematicShowcaseBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(showcaseHex: "#020713"),
                Color(showcaseHex: "#071D3A"),
                Color(showcaseHex: "#0A4F9E"),
                Color(showcaseHex: "#03152B"),
                Color(showcaseHex: "#00040A"),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            LinearGradient(
                colors: [
                    .black.opacity(0.70),
                    .black.opacity(0.08),
                    .black.opacity(0.82),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

extension Color {
    fileprivate init(showcaseHex hex: String) {
        let cleaned = hex.trimmingCharacters(
            in: CharacterSet(charactersIn: "#")
        )
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

private enum ShowcaseExportError: Error {
    case renderFailed
}

extension BattleCardMove {
    fileprivate var showcaseTitle: String {
        switch self {
        case .punch:
            "Tap"
        case .kick:
            "Snap Kick"
        case .dash:
            "Dash Slash"
        case .tornado:
            "Tornado"
        case .roundhouse:
            "Roundhouse"
        case .airSpin:
            "Air Spin"
        case .uppercut:
            "Uppercut"
        case .phantomSlash:
            "Phantom Slash"
        case .meteorKick:
            "Meteor Kick"
        case .bladeStorm:
            "Blade Storm"
        }
    }
}

#Preview {
    ShowcaseView(progress: GameProgressStore(), playSoundEffect: { _ in })
}
