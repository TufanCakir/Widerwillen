//
//  GameView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct GameView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void
    let onExit: (() -> Void)?
    let stopSoundEffects: () -> Void

    private let arena: ArenaConfiguration

    @State private var isPrestigeTransitionVisible = false
    @State private var isPrestigeTransitionRunning = false

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        stopSoundEffects: @escaping () -> Void = {},
        onExit: (() -> Void)? = nil,
        arena: ArenaConfiguration = try! ArenaConfiguration.load()
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.stopSoundEffects = stopSoundEffects
        self.onExit = onExit
        self.arena = arena
    }

    var body: some View {
        ZStack {
            BattleSceneView(
                progress: progress,
                title: "Stage \(max(progress.stage, 1))",
                healthTitle: "Raid HP",
                currentHP: progress.stageHP,
                maxHP: progress.maxStageHP,
                lookIndex: lookIndex(for: progress.stage),
                heroAnimationID: progress.battleHeroAnimationID,
                equippedWeaponImageName: progress.equippedWeaponImageName,
                equippedWeaponBattleAppearance: progress
                    .equippedWeaponBattleAppearance,
                activeSkills: progress.activeBattleSkills,
                onTapAttack: {
                    guard !isPrestigeTransitionRunning else {
                        return BattleAttackResult(damageDealt: 0)
                    }

                    let result = progress.attackStage(
                        damage: progress.tapDamage
                    )
                    playSoundEffect(
                        result.coinsAwarded > 0 ? "stage_clear" : "battle_tap"
                    )
                    return result
                },
                onBattleCardAttack: { card in
                    guard !isPrestigeTransitionRunning else {
                        return BattleAttackResult(damageDealt: 0)
                    }

                    let damage = max(
                        1,
                        Int(
                            (Double(progress.tapDamage) * card.damageMultiplier)
                                .rounded()
                        )
                    )
                    let result = progress.attackStage(damage: damage)
                    playSoundEffect(
                        result.coinsAwarded > 0 ? "stage_clear" : "battle_tap"
                    )
                    return result
                },
                onActiveSkillAttack: { skill in
                    guard !isPrestigeTransitionRunning else {
                        return BattleAttackResult(damageDealt: 0)
                    }

                    playSoundEffect("battle_skill")
                    return progress.attackStage(damage: skill.damage)
                },
                onPrestige: {
                    startPrestigeTransition()
                },
                onExit: {
                    stopSoundEffects()
                    playSoundEffect("ui_back")
                    onExit?()
                },
                arena: arena
            )

            if isPrestigeTransitionVisible {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(30)
                    .allowsHitTesting(true)
            }
        }
        .onAppear {
            progress.prepareStageForBattleStart()
        }
    }

    private func startPrestigeTransition() {
        guard !isPrestigeTransitionRunning, progress.canPrestige else { return }

        isPrestigeTransitionRunning = true
        playSoundEffect("prestige")

        withAnimation(.easeInOut(duration: 0.45)) {
            isPrestigeTransitionVisible = true
        }

        Task {
            try? await Task.sleep(for: .milliseconds(600))

            await MainActor.run {
                progress.prestige()
            }

            try? await Task.sleep(for: .milliseconds(4_400))

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.45)) {
                    isPrestigeTransitionVisible = false
                }
            }

            try? await Task.sleep(for: .milliseconds(450))

            await MainActor.run {
                isPrestigeTransitionRunning = false
            }
        }
    }

    private func lookIndex(for stage: Int) -> Int {
        let count = arena.looks.count
        guard count > 1 else { return 0 }

        let safeStage = max(stage, 1)
        let seed = UInt(safeStage) &* 2_654_435_761
        var index = Int(seed % UInt(count))

        if safeStage > 1 {
            let previousSeed = UInt(safeStage - 1) &* 2_654_435_761
            let previousIndex = Int(previousSeed % UInt(count))
            if index == previousIndex {
                index = (index + 1) % count
            }
        }

        return index
    }
}

#Preview {
    GameView(progress: GameProgressStore())
}
