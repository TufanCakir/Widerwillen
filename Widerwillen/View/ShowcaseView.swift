//
//  ShowcaseView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 30.08.26.
//

import Photos
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
    @State private var isShadowClonePreviewActive = false
    @State private var isCleanMode = false
    @AppStorage("isShowcaseAnimationLoopEnabled") private var isLooping = true

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
                AppBackground()
                    .ignoresSafeArea()

                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .allowsHitTesting(false)

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
                        showcaseControls
                        exportControls
                    }
                    .padding(.horizontal, 14)
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
            .onChange(of: progress.equippedWeaponShadowCloneImageName) { _, _ in
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

    private var showcaseControls: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BattleCardMove.allCases) { move in
                        showcaseMoveButton(move)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .scrollClipDisabled()

            HStack(spacing: 10) {
                Button {
                    playSoundEffect("ui_confirm")
                    isShadowClonePreviewActive.toggle()
                    scene.updateShadowClone(
                        animationID: activeShadowCloneAnimationID
                    )
                } label: {
                    Label(
                        "Shadow",
                        systemImage: isShadowClonePreviewActive
                            ? "person.2.fill" : "person.2"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .background(
                    isShadowClonePreviewActive
                        ? Color.purple.opacity(0.62)
                        : Color.black.opacity(0.42)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    playSoundEffect("attack_manual")
                    scene.playHeroAttackAnimation(move: selectedMove)
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.vertical, 10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
          }

    private func showcaseMoveButton(_ move: BattleCardMove) -> some View {
        let isSelected = selectedMove == move

        return Button {
            playMove(move)
        } label: {
            Text(move.showcaseTitle)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(
                    .white.opacity(isSelected ? 1.0 : 0.45)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var exportControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    Task {
                        await captureSnapshot()
                    }
                } label: {
                    Label(
                        "Save to Photos",
                        systemImage: "photo.badge.arrow.down"
                    )
                    .frame(maxWidth: .infinity)
                }
                .font(.system(size: 14, weight: .heavy))
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(isExporting)

                if !exportStatus.isEmpty {
                    Text(exportStatus)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(.white)
        }
    }

    private func configureScene(size: CGSize) {
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear

        scene.updateBattleCharacter(
            heroAnimationID: progress.battleHeroAnimationID,
            equippedWeaponImageName: progress.equippedWeaponImageName,
            equippedWeaponShadowCloneImageName: progress
                .equippedWeaponShadowCloneImageName,
            equippedWeaponBattleAppearance: progress
                .equippedWeaponBattleAppearance
        )

        let shortestSide = min(size.width, size.height)
        let heroScale = max(0.24, min(0.31, shortestSide / 1350))

        scene.updateShowcaseLayout(
            heroXRatio: 0.5,
            heroYRatio: 1.14,
            heroScale: heroScale
        )

        scene.updateShadowClone(
            animationID: activeShadowCloneAnimationID
        )
    }

    private func playMove(_ move: BattleCardMove) {
        playSoundEffect("attack_manual")
        selectedMove = move
        scene.playHeroAttackAnimation(move: move)
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

    private var activeShadowCloneAnimationID: String? {
        guard isShadowClonePreviewActive else { return nil }

        return progress.activeBattleSkills.first {
            $0.kind == .shadowClone
        }?.companionAnimationID ?? "shadow_clone_nimbi"
    }

    private func imageName(for move: BattleCardMove) -> String {
        battleCards.cards.first { $0.move == move }?.imageName
            ?? battleCards.cards.first { $0.move == move }?.cardImageName
            ?? "icon_pixel_sword"
    }

    private func captureSnapshot() async {
        guard !isExporting else { return }

        isExporting = true
        exportStatus = "Saving snapshot..."

        defer {
            isExporting = false
        }

        do {
            let wasCleanMode = isCleanMode

            withAnimation(.easeInOut(duration: 0.12)) {
                isCleanMode = true
            }

            try await Task.sleep(for: .milliseconds(180))

            let image = try snapshotCurrentScreen()

            try await saveToPhotoLibrary(image)

            exportStatus = "Saved to Photos"

            if !wasCleanMode {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isCleanMode = false
                }
            }

            playSoundEffect("ui_confirm")

        } catch {
            exportStatus = "Could not save snapshot"

            withAnimation(.easeInOut(duration: 0.12)) {
                isCleanMode = false
            }

            playSoundEffect("ui_back")

            print("[ShowcaseView] Photo save failed: \(error)")
        }
    }

    // MARK: - PhotoKit

    private func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(
            for: .addOnly
        )

        guard status == .authorized || status == .limited else {
            throw ShowcaseExportError.photoLibraryDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
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
            window.drawHierarchy(
                in: window.bounds,
                afterScreenUpdates: true
            )
        }
    }
}

private enum ShowcaseExportError: Error {
    case renderFailed
    case photoLibraryDenied
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
