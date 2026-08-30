//
//  SpriteAnimationScene+Textures.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SpriteKit
import UIKit

extension SpriteAnimationScene {
    func configureSprite(
        _ sprite: SKSpriteNode,
        animationID: String,
        columns: Int?,
        rows: Int?,
        frameCount: Int?,
        fps: Double?,
        actionKey: String
    ) {
        let config = resolvedSpriteSheet(
            animationID: animationID,
            columns: columns,
            rows: rows,
            frameCount: frameCount,
            fps: fps
        )
        let textures = Self.textures(for: config)

        sprite.removeAction(forKey: actionKey)
        sprite.texture = textures.first ?? texture(named: config.imageName)

        guard textures.count > 1 else { return }
        sprite.run(
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

    func texture(named imageName: String) -> SKTexture {
        if let url = RemoteContentCache.cachedAssetURL(named: imageName),
            let image = UIImage(contentsOfFile: url.path)
        {
            return SKTexture(image: image)
        }

        return SKTexture(imageNamed: imageName)
    }

    private func resolvedSpriteSheet(
        animationID: String,
        columns: Int?,
        rows: Int?,
        frameCount: Int?,
        fps: Double?
    ) -> SpriteSheet {
        let config = spriteSheets.first {
            $0.id == animationID || $0.imageName == animationID
        }

        return SpriteSheet(
            id: config?.id ?? animationID,
            imageName: config?.imageName ?? animationID,
            columns: max(columns ?? config?.columns ?? 1, 1),
            rows: max(rows ?? config?.rows ?? 1, 1),
            spacing: max(config?.spacing ?? 0, 0),
            margin: max(config?.margin ?? 0, 0),
            frameCount: max(frameCount ?? config?.frameCount ?? 1, 1),
            fps: max(fps ?? config?.fps ?? 8, 1)
        )
    }

    private static let spriteSheetTextureCache =
        NSCache<NSString, SpriteSheetTextureCacheEntry>()

    private static func textures(for config: SpriteSheet) -> [SKTexture] {
        let cacheKey =
            [
                config.imageName,
                "\(config.columns)",
                "\(config.rows)",
                "\(config.spacing)",
                "\(config.margin)",
                "\(config.frameCount)",
            ].joined(separator: "|") as NSString

        if let cachedEntry = spriteSheetTextureCache.object(forKey: cacheKey) {
            return cachedEntry.textures
        }

        let sheet = baseTexture(named: config.imageName)
        sheet.filteringMode = .nearest
        let textures = slicedTextures(from: sheet, config: config)
        spriteSheetTextureCache.setObject(
            SpriteSheetTextureCacheEntry(textures: textures),
            forKey: cacheKey
        )
        return textures
    }

    private static func baseTexture(named imageName: String) -> SKTexture {
        if let url = RemoteContentCache.cachedAssetURL(named: imageName),
            let image = UIImage(contentsOfFile: url.path)
        {
            return SKTexture(image: image)
        }

        return SKTexture(imageNamed: imageName)
    }

    private static func slicedTextures(
        from sheet: SKTexture,
        config: SpriteSheet
    ) -> [SKTexture] {
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

        guard sheetSize.width > 0, sheetSize.height > 0,
            frameSize.width > 0, frameSize.height > 0
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

private final class SpriteSheetTextureCacheEntry {
    let textures: [SKTexture]

    init(textures: [SKTexture]) {
        self.textures = textures
    }
}
