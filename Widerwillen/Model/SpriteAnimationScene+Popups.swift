//
//  SpriteAnimationScene+Popups.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SpriteKit
import UIKit

extension SpriteAnimationScene {
    func showPopup(
        text: String,
        color: UIColor,
        xRatio: Double,
        yRatio: Double,
        imageName: String? = nil
    ) {
        let popup = SKNode()
        popup.name = "battlePopup"
        popup.zPosition = 10_000
        popup.position = CGPoint(
            x: size.width * min(max(xRatio, 0), 1),
            y: size.height * (1 - min(max(yRatio, 0), 1))
        )

        var nextY: CGFloat = 0
        if let imageName {
            let icon = SKSpriteNode(texture: texture(named: imageName))
            icon.size = CGSize(width: 28, height: 28)
            icon.position = CGPoint(x: 0, y: nextY + 16)
            popup.addChild(icon)
            nextY += 28
        }

        if !text.isEmpty {
            let label = SKLabelNode(text: text)
            label.fontName = WiderwillenTypography.fontName
            label.fontSize = 18
            label.fontColor = color
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: nextY)
            popup.addChild(label)
        }

        addChild(popup)
        trimBattlePopups()

        popup.run(
            .sequence([
                .group([
                    .moveBy(x: 0, y: 42, duration: 0.85),
                    .fadeOut(withDuration: 0.85),
                    .scale(to: 1.15, duration: 0.85),
                ]),
                .removeFromParent(),
            ])
        )
    }

    private func trimBattlePopups(maxCount: Int = 16) {
        let popups = children.filter { $0.name == "battlePopup" }
        guard popups.count > maxCount else { return }

        for popup in popups.prefix(popups.count - maxCount) {
            popup.removeFromParent()
        }
    }
}
