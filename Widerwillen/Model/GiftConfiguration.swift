//
//  GiftConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct GiftConfiguration: Decodable {
    let gifts: [GiftReward]

    static func load(named resourceName: String = "gift") throws
        -> GiftConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct GiftReward: Decodable, Identifiable {
    let id: String
    let title: String
    let titleKey: String?
    let category: String
    let categoryKey: String?
    let imageName: String
    let rewards: [TradeResourceAmount]
    let unlocks: [TradeUnlockReward]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleKey
        case category
        case categoryKey
        case imageName
        case rewards
        case unlocks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        titleKey = try container.decodeIfPresent(String.self, forKey: .titleKey)
        category = try container.decode(String.self, forKey: .category)
        categoryKey = try container.decodeIfPresent(
            String.self,
            forKey: .categoryKey
        )
        imageName = try container.decode(String.self, forKey: .imageName)
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
