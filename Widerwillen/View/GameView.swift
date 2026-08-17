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

    @State private var isPrestigeTransitionVisible = false
    @State private var isPrestigeTransitionRunning = false

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        stopSoundEffects: @escaping () -> Void = {},
        onExit: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.stopSoundEffects = stopSoundEffects
        self.onExit = onExit
    }

    var body: some View {
        ZStack {
            BattleSceneView(
                progress: progress,
                title: "Stage \(progress.stage)",
                healthTitle: "Raid HP",
                currentHP: progress.stageHP,
                maxHP: progress.maxStageHP,
                lookIndex: lookIndex(for: progress.stage),
                heroAnimationID: progress.battleHeroAnimationID,
                companionAnimationIDs: progress.battleCompanionAnimationIDs,
                spriteAttackInterval: progress.spriteAttackInterval,
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
                onSpriteAttack: {
                    guard
                        !isPrestigeTransitionRunning,
                        progress.hasCompanionSprites
                    else {
                        return BattleAttackResult(damageDealt: 0)
                    }

                    let result = progress.attackStage(
                        damage: progress.spriteDamage
                    )
                    playSoundEffect(
                        result.coinsAwarded > 0
                            ? "stage_clear"
                            : "battle_sprite_attack"
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
                }
            )

            if isPrestigeTransitionVisible {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(30)
                    .allowsHitTesting(true)
            }
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
        stage / 10
    }
}

#Preview {
    GameView(progress: GameProgressStore())
}
