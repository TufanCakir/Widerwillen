//
//  GameView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct GameView: View {
    let progress: GameProgressStore
    let onExit: (() -> Void)?

    init(
        progress: GameProgressStore,
        onExit: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.onExit = onExit
    }

    var body: some View {
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
            onTapAttack: {
                progress.attackStage(damage: progress.tapDamage)
            },
            onSpriteAttack: {
                guard progress.hasCompanionSprites else {
                    return BattleAttackResult(damageDealt: 0)
                }

                return progress.attackStage(damage: progress.spriteDamage)
            },
            onPrestige: {
                progress.prestige()
            },
            onExit: onExit
        )
    }

    private func lookIndex(for stage: Int) -> Int {
        stage / 10
    }
}

#Preview {
    GameView(progress: GameProgressStore())
}
