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
    let startDate: Date?
    let endDate: Date?
    let imageName: String
    let rewards: [TradeResourceAmount]
    let unlocks: [TradeUnlockReward]

    var schedule: ContentSchedule {
        ContentSchedule(startDate: startDate, endDate: endDate)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleKey
        case category
        case categoryKey
        case startDate
        case endDate
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
        // Legacy gifts without an expiry are deliberately unavailable.
        let start = try container.decodeIfPresent(
            String.self,
            forKey: .startDate
        )
        let end = try container.decodeIfPresent(String.self, forKey: .endDate)
        startDate = start.map { GermanDateParser.parse($0) ?? .distantFuture }
        endDate = end.flatMap(GermanDateParser.parse) ?? .distantPast
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
