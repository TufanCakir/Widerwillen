//
//  SpriteSheetAnimation.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SpriteKit
import UIKit

final class SpriteSheetAnimation {

    private let config: SpriteSheet
    private let textures: [SKTexture]
    private let actionKey = "spriteSheetAnimation"
    private let attackActionKey = "spriteSheetAttackAnimation"

    init(config: SpriteSheet = try! SpriteSheet.load()) {
        self.config = config

        guard
            let url = RemoteContentCache.cachedAssetURL(named: config.imageName),
            let image = UIImage(contentsOfFile: url.path)
        else {
            textures = []
            return
        }

        let sheet = SKTexture(image: image)
        sheet.filteringMode = .nearest
        textures = Self.textures(from: sheet, config: config)
    }

    var firstTexture: SKTexture? { textures.first }

    func showFirstFrame(on node: SKSpriteNode) {
        node.removeAction(forKey: actionKey)
        node.removeAction(forKey: attackActionKey)
        node.texture = firstTexture
    }

    func start(on node: SKSpriteNode) {
        guard !textures.isEmpty else { return }

        node.texture = firstTexture
        node.removeAction(forKey: actionKey)

        guard textures.count > 1 else { return }

        node.run(
            .repeatForever(
                .animate(
                    with: textures,
                    timePerFrame: 1 / max(config.fps, 1),
                    resize: false,
                    restore: false
                )
            ),
            withKey: actionKey
        )
    }

    func stop(on node: SKSpriteNode) {
        node.removeAction(forKey: actionKey)
    }

    func playOnce(on node: SKSpriteNode) {
        guard !textures.isEmpty else { return }

        node.removeAction(forKey: actionKey)
        node.removeAction(forKey: attackActionKey)

        guard textures.count > 1 else {
            node.texture = firstTexture
            return
        }

        let animation = SKAction.animate(
            with: textures,
            timePerFrame: 1 / max(config.fps, 1),
            resize: false,
            restore: false
        )
        let returnToIdle = SKAction.run { [weak node, firstTexture] in
            node?.texture = firstTexture
        }

        node.run(.sequence([animation, returnToIdle]), withKey: attackActionKey)
    }

    func size(fitting container: CGSize, scale: CGFloat = 0.7) -> CGSize {
        guard let textureSize = firstTexture?.size(), textureSize.width > 0,
            textureSize.height > 0
        else {
            return .zero
        }

        let factor =
            min(container.width, container.height) * scale
            / max(textureSize.width, textureSize.height)
        return CGSize(
            width: textureSize.width * factor,
            height: textureSize.height * factor
        )
    }

    private static func textures(from sheet: SKTexture, config: SpriteSheet)
        -> [SKTexture]
    {
        guard config.columns > 0, config.rows > 0, config.frameCount > 0 else {
            return []
        }

        let sheetSize = sheet.size()
        let columns = CGFloat(config.columns)
        let rows = CGFloat(config.rows)
        let spacing = CGFloat(config.spacing)
        let margin = CGFloat(config.margin)
        let frameSize = CGSize(
            width: (sheetSize.width - margin * 2 - spacing * (columns - 1))
                / columns,
            height: (sheetSize.height - margin * 2 - spacing * (rows - 1))
                / rows
        )

        guard sheetSize.width > 0, sheetSize.height > 0, frameSize.width > 0,
            frameSize.height > 0
        else {
            return []
        }

        return (0..<min(config.frameCount, config.columns * config.rows)).map {
            index in
            let column = CGFloat(index % config.columns)
            let row = CGFloat(index / config.columns)
            let rect = CGRect(
                x: (margin + column * (frameSize.width + spacing))
                    / sheetSize.width,
                y: (sheetSize.height - margin - (row + 1) * frameSize.height
                    - row * spacing) / sheetSize.height,
                width: frameSize.width / sheetSize.width,
                height: frameSize.height / sheetSize.height
            )
            let texture = SKTexture(rect: rect, in: sheet)
            texture.filteringMode = .nearest
            return texture
        }
    }
}
