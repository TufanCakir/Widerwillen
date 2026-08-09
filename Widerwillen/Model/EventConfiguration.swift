//
//  EventConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct EventConfiguration: Decodable {
    let events: [GameEvent]

    static func load(named resourceName: String = "event") throws
        -> EventConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct GameEvent: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
    let bannerImageName: String
    let currencyName: String
    let currencyImageName: String
    let dailyLimit: Int
    let hp: Int
    let rewards: EventRewards

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case bannerImageName
        case currencyName
        case currencyImageName
        case dailyLimit
        case hp
        case rewards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category =
            try container.decodeIfPresent(String.self, forKey: .category)
            ?? "Featured"
        bannerImageName = try container.decode(
            String.self,
            forKey: .bannerImageName
        )
        currencyName = try container.decode(String.self, forKey: .currencyName)
        currencyImageName = try container.decode(
            String.self,
            forKey: .currencyImageName
        )
        dailyLimit = try container.decode(Int.self, forKey: .dailyLimit)
        hp = try container.decode(Int.self, forKey: .hp)
        rewards = try container.decode(EventRewards.self, forKey: .rewards)
    }
}

struct EventRewards: Decodable {
    let eventCurrency: Int
    let coins: Int
    let crystals: Int
    let relics: Int

    private enum CodingKeys: String, CodingKey {
        case eventCurrency
        case coins
        case crystals
        case relics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventCurrency = try container.decode(Int.self, forKey: .eventCurrency)
        coins = try container.decode(Int.self, forKey: .coins)
        crystals = try container.decode(Int.self, forKey: .crystals)
        relics = try container.decodeIfPresent(Int.self, forKey: .relics) ?? 0
    }
}
