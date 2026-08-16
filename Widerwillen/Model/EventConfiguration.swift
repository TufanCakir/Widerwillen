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
        let configuration = try JSONLoader.load(
            EventConfiguration.self,
            named: resourceName
        )
        let chips = try? ChipConfiguration.load()
        return configuration.resolved(with: chips)
    }

    private func resolved(with chipConfiguration: ChipConfiguration?)
        -> EventConfiguration
    {
        EventConfiguration(
            events: events.map { event in
                event.resolved(with: chipConfiguration?.chip(id: event.chipID))
            }
        )
    }
}

struct GameEvent: Decodable, Identifiable {
    let id: String
    let title: String
    let titleKey: String?
    let category: String
    let categoryKey: String?
    let bannerImageName: String
    let battleGroundImageName: String?
    let currencyName: String
    let currencyNameKey: String?
    let currencyImageName: String
    let chipID: String?
    let cardBackgroundImageName: String?
    let battleBackgroundImageName: String?
    let victory: EventVictoryPresentation
    let dailyLimit: Int
    let hp: Int
    let rewards: EventRewards
    var currencyStorageID: String { chipID ?? id }
  
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleKey
        case category
        case categoryKey
        case bannerImageName
        case battleGroundImageName
        case currencyName
        case currencyNameKey
        case currencyImageName
        case chipID
        case cardBackgroundImageName
        case battleBackgroundImageName
        case victory
        case dailyLimit
        case hp
        case rewards
    }

    init(
        id: String,
        title: String,
        titleKey: String?,
        category: String,
        categoryKey: String?,
        bannerImageName: String,
        currencyName: String,
        currencyNameKey: String?,
        currencyImageName: String,
        chipID: String?,
        cardBackgroundImageName: String?,
        battleBackgroundImageName: String?,
        battleGroundImageName: String?,
        victory: EventVictoryPresentation,
        dailyLimit: Int,
        hp: Int,
        rewards: EventRewards
    ) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.category = category
        self.categoryKey = categoryKey
        self.bannerImageName = bannerImageName
        self.currencyName = currencyName
        self.currencyNameKey = currencyNameKey
        self.currencyImageName = currencyImageName
        self.chipID = chipID
        self.cardBackgroundImageName = cardBackgroundImageName
        self.battleBackgroundImageName = battleBackgroundImageName
        self.battleGroundImageName = battleGroundImageName
        self.victory = victory
        self.dailyLimit = dailyLimit
        self.hp = hp
        self.rewards = rewards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        titleKey = try container.decodeIfPresent(String.self, forKey: .titleKey)
        category =
            try container.decodeIfPresent(String.self, forKey: .category)
            ?? "Featured"
        categoryKey = try container.decodeIfPresent(
            String.self,
            forKey: .categoryKey
        )
        bannerImageName = try container.decode(
            String.self,
            forKey: .bannerImageName
        )
        chipID = try container.decodeIfPresent(String.self, forKey: .chipID)
        currencyName =
            try container.decodeIfPresent(String.self, forKey: .currencyName)
            ?? "Event Chips"
        currencyNameKey = try container.decodeIfPresent(
            String.self,
            forKey: .currencyNameKey
        )
        currencyImageName = try container.decodeIfPresent(
            String.self,
            forKey: .currencyImageName
        ) ?? "icon_pixel_chip_blue"
        cardBackgroundImageName = try container.decodeIfPresent(
            String.self,
            forKey: .cardBackgroundImageName
        )
        battleBackgroundImageName = try container.decodeIfPresent(
            String.self,
            forKey: .battleBackgroundImageName
        )
        battleGroundImageName = try container.decodeIfPresent(
            String.self,
            forKey: .battleGroundImageName
        )
        victory =
            try container.decodeIfPresent(
                EventVictoryPresentation.self,
                forKey: .victory
            ) ?? EventVictoryPresentation()
        dailyLimit = try container.decode(Int.self, forKey: .dailyLimit)
        hp = try container.decode(Int.self, forKey: .hp)
        rewards = try container.decode(EventRewards.self, forKey: .rewards)
    }

    func resolved(with chip: EventChip?) -> GameEvent {
        guard let chip else { return self }

        return GameEvent(
            id: id,
            title: title,
            titleKey: titleKey,
            category: category,
            categoryKey: categoryKey,
            bannerImageName: bannerImageName,
            currencyName: chip.name,
            currencyNameKey: chip.nameKey,
            currencyImageName: chip.imageName,
            chipID: chip.id,
            cardBackgroundImageName: cardBackgroundImageName,
            battleBackgroundImageName: battleBackgroundImageName,
            battleGroundImageName: battleGroundImageName,
            victory: victory,
            dailyLimit: dailyLimit,
            hp: hp,
            rewards: rewards
        )
    }
}

struct EventVictoryPresentation: Decodable {
    let title: String
    let titleKey: String?
    let imageName: String?
    let backgroundImageName: String
    let dismissDelaySeconds: Double

    init(
        title: String = "Victory",
        titleKey: String? = "event.victory",
        imageName: String? = nil,
        backgroundImageName: String = "bg_app",
        dismissDelaySeconds: Double = 2.4
    ) {
        self.title = title
        self.titleKey = titleKey
        self.imageName = imageName
        self.backgroundImageName = backgroundImageName
        self.dismissDelaySeconds = dismissDelaySeconds
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case titleKey
        case imageName
        case backgroundImageName
        case dismissDelaySeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title =
            try container.decodeIfPresent(String.self, forKey: .title)
            ?? "Victory"
        titleKey = try container.decodeIfPresent(String.self, forKey: .titleKey)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        backgroundImageName =
            try container.decodeIfPresent(
                String.self,
                forKey: .backgroundImageName
            ) ?? "bg_app"
        dismissDelaySeconds =
            try container.decodeIfPresent(
                Double.self,
                forKey: .dismissDelaySeconds
            ) ?? 2.4
    }
}

struct EventRewards: Decodable {
    let chipAmount: Int
    let coins: Int
    let crystals: Int
    let relics: Int

    private enum CodingKeys: String, CodingKey {
        case chipAmount
        case eventCurrency
        case coins
        case crystals
        case relics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chipAmount =
            try container.decodeIfPresent(Int.self, forKey: .chipAmount)
            ?? container.decode(Int.self, forKey: .eventCurrency)
        coins = try container.decode(Int.self, forKey: .coins)
        crystals = try container.decode(Int.self, forKey: .crystals)
        relics = try container.decodeIfPresent(Int.self, forKey: .relics) ?? 0
    }
}
