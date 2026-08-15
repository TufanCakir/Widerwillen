//
//  TradeConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct TradeConfiguration: Decodable {
    let offers: [TradeOffer]

    static func load(named resourceName: String = "trade") throws
        -> TradeConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct TradeOffer: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
    let imageName: String
    let limit: Int?
    let costs: [TradeResourceAmount]
    let rewards: [TradeResourceAmount]
    let unlocks: [TradeUnlockReward]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case imageName
        case limit
        case costs
        case rewards
        case unlocks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        imageName = try container.decode(String.self, forKey: .imageName)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
        costs =
            try container.decodeIfPresent(
                [TradeResourceAmount].self,
                forKey: .costs
            ) ?? []
        rewards =
            try container.decodeIfPresent(
                [TradeResourceAmount].self,
                forKey: .rewards
            ) ?? []
        unlocks =
            try container.decodeIfPresent(
                [TradeUnlockReward].self,
                forKey: .unlocks
            ) ?? []
    }
}

struct TradeResourceAmount: Decodable, Identifiable {
    var id: String {
        "\(resource.rawValue)-\(eventID ?? "global")-\(amount)"
    }

    let resource: TradeResource
    let amount: Int
    let eventID: String?
    let imageName: String?
}

enum TradeResource: String, Codable {
    case coins
    case crystals
    case relics
    case skillBooks = "skill_books"
    case eventCurrency = "event_currency"

    var imageName: String {
        switch self {
        case .coins:
            "icon_pixel_coin"
        case .crystals:
            "icon_pixel_crystal"
        case .relics:
            "icon_pixel_relic"
        case .skillBooks:
            "icon_pixel_skill_book"
        case .eventCurrency:
            "icon_pixel_chip_blue"
        }
    }
}

struct TradeUnlockReward: Decodable, Identifiable {
    let id: String
    let kind: TradeUnlockKind
    let name: String
    let imageName: String
    let characterID: String?
    let skinID: String?
    let itemID: String?
    let rarity: SpriteRarity?
    let damageBonus: Int?
}

enum TradeUnlockKind: String, Codable {
    case character
    case skin
    case item
}
