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

    init(
        id: String,
        imageName: String,
        columns: Int = 1,
        rows: Int = 1,
        spacing: Int = 0,
        margin: Int = 0,
        frameCount: Int = 1,
        fps: Double = 8,
        xPosition: CGFloat? = nil,
        yOffset: CGFloat? = nil,
        scale: CGFloat? = nil,
        gridColumn: Int? = nil,
        gridRow: Int? = nil
    ) {
        self.id = id
        self.imageName = imageName
        self.columns = columns
        self.rows = rows
        self.spacing = spacing
        self.margin = margin
        self.frameCount = frameCount
        self.fps = fps
        self.xPosition = xPosition
        self.yOffset = yOffset
        self.scale = scale
        self.gridColumn = gridColumn
        self.gridRow = gridRow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageName = try container.decode(String.self, forKey: .imageName)
        id =
            try container.decodeIfPresent(String.self, forKey: .id) ?? imageName
        columns = try container.decode(Int.self, forKey: .columns)
        rows = try container.decode(Int.self, forKey: .rows)
        spacing = try container.decode(Int.self, forKey: .spacing)
        margin = try container.decode(Int.self, forKey: .margin)
        frameCount = try container.decode(Int.self, forKey: .frameCount)
        fps = try container.decode(Double.self, forKey: .fps)
        xPosition = try container.decodeIfPresent(
            CGFloat.self,
            forKey: .xPosition
        )
        yOffset = try container.decodeIfPresent(CGFloat.self, forKey: .yOffset)
        scale = try container.decodeIfPresent(CGFloat.self, forKey: .scale)
        gridColumn = try container.decodeIfPresent(
            Int.self,
            forKey: .gridColumn
        )
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

struct SpriteRig: Codable, Identifiable {
    let id: String
    let title: String
    let canvasSize: CGFloat
    let parts: [String: String]
    let joints: [String: SpriteRigJoint]

    static func loadAll(
        named resourceName: String = "rig",
        bundle: Bundle = .main
    ) throws -> [SpriteRig] {
        try JSONLoader.load(
            [SpriteRig].self,
            named: resourceName,
            bundle: bundle
        )
    }
}

struct SpriteRigJoint: Codable {
    let x: CGFloat
    let y: CGFloat
}

struct BattleCardConfiguration: Decodable {
    let cards: [BattleCardDefinition]

    init(cards: [BattleCardDefinition]) {
        self.cards = cards
    }

    static func load(named resourceName: String = "battle_card") throws
        -> BattleCardConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct BattleCardDefinition: Decodable, Identifiable {
    let id: String
    let title: String
    let move: BattleCardMove
    let style: String
    let imageName: String?
    let cardImageName: String?
    let backgroundImageName: String?
    let cooldownSeconds: Double
    let staminaCost: Int
    let damageMultiplier: Double
    let gradientColors: [String]
    let requiredSkillID: String?
    let requiredSkillLevel: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case move
        case style
        case imageName
        case cardImage
        case cardImageName
        case backgroundImageName
        case cooldownSeconds
        case staminaCost
        case damageMultiplier
        case gradientColors
        case requiredSkillID
        case requiredSkillLevel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        move =
            try container.decodeIfPresent(BattleCardMove.self, forKey: .move)
            ?? .punch
        style =
            try container.decodeIfPresent(String.self, forKey: .style)
            ?? "Strike"
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        cardImageName =
            try container.decodeIfPresent(String.self, forKey: .cardImageName)
            ?? container.decodeIfPresent(String.self, forKey: .cardImage)
        backgroundImageName = try container.decodeIfPresent(
            String.self,
            forKey: .backgroundImageName
        )
        cooldownSeconds =
            try container.decodeIfPresent(
                Double.self,
                forKey: .cooldownSeconds
            ) ?? 0.45
        staminaCost =
            try container.decodeIfPresent(Int.self, forKey: .staminaCost) ?? 0
        damageMultiplier =
            try container.decodeIfPresent(
                Double.self,
                forKey: .damageMultiplier
            ) ?? 1
        gradientColors =
            try container.decodeIfPresent(
                [String].self,
                forKey: .gradientColors
            ) ?? ["#ffffff", "#a8d8ff"]
        requiredSkillID =
            try container.decodeIfPresent(String.self, forKey: .requiredSkillID)
        requiredSkillLevel =
            try container.decodeIfPresent(
                Int.self,
                forKey: .requiredSkillLevel
            ) ?? 1
    }
}

enum BattleCardMove: String, Codable, CaseIterable, Identifiable {
    case punch
    case kick
    case dash
    case tornado
    case roundhouse
    case airSpin

    var id: String { rawValue }
}
