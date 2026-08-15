//
//  SummonConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation
import SwiftUI

struct SummonConfiguration: Decodable {
    let banners: [SummonBanner]

    static func load(named resourceName: String = "summon") throws
        -> SummonConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct SummonBanner: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
    let kind: SummonKind
    let bannerImageName: String
    let currencyImageName: String
    let singleCost: Int
    let multiCost: Int
    let multiCount: Int
    let requiredAccountLevel: Int
    let entries: [SummonEntry]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case kind
        case bannerImageName
        case currencyImageName
        case singleCost
        case multiCost
        case multiCount
        case requiredAccountLevel
        case entries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category =
            try container.decodeIfPresent(String.self, forKey: .category)
            ?? "Sprites"
        kind =
            try container.decodeIfPresent(SummonKind.self, forKey: .kind)
            ?? .sprite
        bannerImageName = try container.decode(
            String.self,
            forKey: .bannerImageName
        )
        currencyImageName =
            try container.decodeIfPresent(
                String.self,
                forKey: .currencyImageName
            )
            ?? (kind == .relic ? "icon_pixel_relic" : "icon_pixel_crystal")
        singleCost = try container.decode(Int.self, forKey: .singleCost)
        multiCost = try container.decode(Int.self, forKey: .multiCost)
        multiCount = try container.decode(Int.self, forKey: .multiCount)
        requiredAccountLevel =
            try container.decodeIfPresent(
                Int.self,
                forKey: .requiredAccountLevel
            ) ?? 1
        entries = try container.decode([SummonEntry].self, forKey: .entries)
    }
}

struct SummonEntry: Decodable, Identifiable {
    let id: String
    let name: String
    let spriteIndex: Int?
    let characterID: String?
    let skinID: String?
    let companionID: String?
    let imageName: String
    let rarity: SpriteRarity
    let damageBonus: Int
    let weight: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case spriteIndex
        case characterID
        case skinID
        case companionID
        case imageName
        case rarity
        case damageBonus
        case weight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        spriteIndex = try container.decodeIfPresent(
            Int.self,
            forKey: .spriteIndex
        )
        characterID = try container.decodeIfPresent(
            String.self,
            forKey: .characterID
        )
        skinID = try container.decodeIfPresent(String.self, forKey: .skinID)
        companionID = try container.decodeIfPresent(
            String.self,
            forKey: .companionID
        )
        imageName = try container.decode(String.self, forKey: .imageName)
        rarity = try container.decode(SpriteRarity.self, forKey: .rarity)
        damageBonus =
            try container.decodeIfPresent(Int.self, forKey: .damageBonus) ?? 1
        weight = try container.decode(Double.self, forKey: .weight)
    }
}

enum SummonKind: String, Codable {
    case sprite
    case relic
    case item
}

enum SpriteRarity: String, Codable {
    case common
    case rare
    case epic
    case legendary

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .common:
            .white
        case .rare:
            .cyan
        case .epic:
            .purple
        case .legendary:
            .yellow
        }
    }
}
