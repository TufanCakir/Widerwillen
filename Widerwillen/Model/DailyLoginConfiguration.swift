//
//  DailyLoginConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct DailyLoginConfiguration: Decodable {
    let rewards: [DailyLoginReward]

    static func load(named resourceName: String = "daily_login") throws
        -> DailyLoginConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct DailyLoginReward: Decodable, Identifiable {
    var id: Int { day }

    let day: Int
    let title: String
    let imageName: String
    let rewards: [TradeResourceAmount]
}
