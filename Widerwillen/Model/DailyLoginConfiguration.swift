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
    let category: String
    let categoryKey: String?
    let backgroundImageName: String
    let rewards: [DailyLoginReward]
}

struct DailyLoginReward: Decodable, Identifiable {
    var id: Int { day }

    let day: Int
    let title: String
    let titleKey: String?
    let imageName: String
    let rewards: [TradeResourceAmount]
}
