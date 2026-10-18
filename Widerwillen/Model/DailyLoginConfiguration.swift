//
//  DailyLoginConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct DailyLoginConfiguration: Decodable {
    let logins: [DailyLoginCampaign]
    let rewards: [DailyLoginReward]

    private enum CodingKeys: String, CodingKey {
        case logins
        case rewards
    }

    init(logins: [DailyLoginCampaign]) {
        self.logins = logins
        self.rewards = logins.first?.rewards ?? []
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedLogins =
            try container.decodeIfPresent(
                [DailyLoginCampaign].self,
                forKey: .logins
            ) ?? []

        if !decodedLogins.isEmpty {
            logins = decodedLogins
            rewards = decodedLogins.first?.rewards ?? []
        } else {
            let legacyRewards =
                try container.decodeIfPresent(
                    [DailyLoginReward].self,
                    forKey: .rewards
                ) ?? []
            logins = [
                DailyLoginCampaign(
                    id: "standard",
                    title: "Daily Login",
                    titleKey: "daily_login.standard.title",
                    startDate: nil,
                    endDate: nil,
                    category: "Daily",
                    categoryKey: "daily_login.category.daily",
                    backgroundImageName: "bg_blue",
                    rewards: legacyRewards
                )
            ]
            rewards = legacyRewards
        }
    }

    static func load(named resourceName: String = "daily_login") throws
        -> DailyLoginConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct DailyLoginCampaign: Decodable, Identifiable {
    let id: String
    let title: String
    let titleKey: String?
    let startDate: Date?
    let endDate: Date?
    let category: String
    let categoryKey: String?
    let backgroundImageName: String
    let rewards: [DailyLoginReward]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleKey
        case startDate
        case endDate
        case category
        case categoryKey
        case backgroundImageName
        case rewards
    }

    init(
        id: String,
        title: String,
        titleKey: String?,
        startDate: Date?,
        endDate: Date?,
        category: String,
        categoryKey: String?,
        backgroundImageName: String,
        rewards: [DailyLoginReward]
    ) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.categoryKey = categoryKey
        self.backgroundImageName = backgroundImageName
        self.rewards = rewards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        titleKey = try container.decodeIfPresent(String.self, forKey: .titleKey)
        startDate = try Self.decodeGermanDate(
            from: container,
            forKey: .startDate
        )
        endDate = try Self.decodeGermanDate(from: container, forKey: .endDate)
        category = try container.decode(String.self, forKey: .category)
        categoryKey = try container.decodeIfPresent(
            String.self,
            forKey: .categoryKey
        )
        backgroundImageName = try container.decode(
            String.self,
            forKey: .backgroundImageName
        )
        rewards = try container.decode([DailyLoginReward].self, forKey: .rewards)
    }

    var schedule: ContentSchedule {
        ContentSchedule(startDate: startDate, endDate: endDate)
    }

    func availability(at date: Date = .now) -> ContentAvailability {
        schedule.availability(at: date)
    }

    func isActive(at date: Date = .now) -> Bool {
        schedule.isActive(at: date)
    }

    private static func decodeGermanDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Date? {
        guard let value = try container.decodeIfPresent(
            String.self,
            forKey: key
        ) else {
            return nil
        }

        guard let date = GermanDateParser.parse(value) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription:
                    "Ungültiges Datum '\(value)'. Erwartet: TT.MM.JJJJ HH:mm"
            )
        }

        return date
    }
}

struct DailyLoginReward: Decodable, Identifiable {
    var id: Int { day }

    let day: Int
    let title: String
    let titleKey: String?
    let imageName: String
    let rewards: [TradeResourceAmount]
    let unlocks: [TradeUnlockReward]

    private enum CodingKeys: String, CodingKey {
        case day
        case title
        case titleKey
        case imageName
        case rewards
        case unlocks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(Int.self, forKey: .day)
        title = try container.decode(String.self, forKey: .title)
        titleKey = try container.decodeIfPresent(String.self, forKey: .titleKey)
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
