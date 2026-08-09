//
//  SpriteSheet.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import CoreGraphics
import Foundation

struct SpriteSheet: Codable {
    let imageName: String
    let columns: Int
    let rows: Int
    let spacing: Int
    let margin: Int
    let frameCount: Int
    let fps: Double
    let xPosition: CGFloat?
    let yOffset: CGFloat?
    let scale: CGFloat?
    let gridColumn: Int?
    let gridRow: Int?

    static func load(
        named resourceName: String = "spritesheet",
        bundle: Bundle = .main
    ) throws -> SpriteSheet {
        guard
            let firstSheet = try loadAll(named: resourceName, bundle: bundle)
                .first
        else {
            throw Error.emptySpriteSheetList
        }
        return firstSheet
    }

    static func loadAll(
        named resourceName: String = "spritesheet",
        bundle: Bundle = .main
    ) throws -> [SpriteSheet] {
        do {
            return try JSONLoader.load(
                [SpriteSheet].self,
                named: resourceName,
                bundle: bundle
            )
        } catch {
            return [
                try JSONLoader.load(
                    SpriteSheet.self,
                    named: resourceName,
                    bundle: bundle
                )
            ]
        }
    }
}

extension SpriteSheet {
    enum Error: LocalizedError {
        case emptySpriteSheetList

        var errorDescription: String? {
            switch self {
            case .emptySpriteSheetList:
                "spritesheet.json does not contain any sprites."
            }
        }
    }
}
