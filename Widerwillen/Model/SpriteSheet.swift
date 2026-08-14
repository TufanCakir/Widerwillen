//
//  SpriteSheet.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import CoreGraphics
import Foundation

struct SpriteSheet: Codable {
    let id: String
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

    private enum CodingKeys: String, CodingKey {
        case id
        case imageName
        case columns
        case rows
        case spacing
        case margin
        case frameCount
        case fps
        case xPosition
        case yOffset
        case scale
        case gridColumn
        case gridRow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageName = try container.decode(String.self, forKey: .imageName)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? imageName
        columns = try container.decode(Int.self, forKey: .columns)
        rows = try container.decode(Int.self, forKey: .rows)
        spacing = try container.decode(Int.self, forKey: .spacing)
        margin = try container.decode(Int.self, forKey: .margin)
        frameCount = try container.decode(Int.self, forKey: .frameCount)
        fps = try container.decode(Double.self, forKey: .fps)
        xPosition = try container.decodeIfPresent(CGFloat.self, forKey: .xPosition)
        yOffset = try container.decodeIfPresent(CGFloat.self, forKey: .yOffset)
        scale = try container.decodeIfPresent(CGFloat.self, forKey: .scale)
        gridColumn = try container.decodeIfPresent(Int.self, forKey: .gridColumn)
        gridRow = try container.decodeIfPresent(Int.self, forKey: .gridRow)
    }

    static func load(
        named resourceName: String = "animation",
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
        named resourceName: String = "animation",
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
                "animation.json does not contain any animations."
            }
        }
    }
}
