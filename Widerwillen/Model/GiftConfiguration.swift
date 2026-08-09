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
    let category: String
    let imageName: String
    let rewards: [TradeResourceAmount]
}
