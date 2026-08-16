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

    private enum CodingKeys: String, CodingKey {
        case resource
        case amount
        case eventID
        case chipID
        case imageName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(TradeResource.self, forKey: .resource)
        amount = try container.decode(Int.self, forKey: .amount)
        eventID =
            try container.decodeIfPresent(String.self, forKey: .chipID)
            ?? container.decodeIfPresent(String.self, forKey: .eventID)
        imageName = try container.decodeIfPresent(
            String.self,
            forKey: .imageName
        )
    }
}

enum TradeResource: String, Codable {
    case coins
    case crystals
    case relics
    case skillBooks = "skill_books"
    case eventChip = "event_chip"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "event_currency":
            self = .eventChip
        default:
            guard let resource = TradeResource(rawValue: rawValue) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown trade resource: \(rawValue)"
                )
            }
            self = resource
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

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
        case .eventChip:
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
