//
//  PassConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct PassConfiguration: Decodable {
    let passes: [BattlePassDefinition]

    init(passes: [BattlePassDefinition]) {
        self.passes = passes
    }

    static func load(named resourceName: String = "pass") throws
        -> PassConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct BattlePassDefinition: Decodable, Identifiable {
    let id: String
    let title: String
    let season: String
    let category: String?
    let purchaseType: ShopPurchaseType
    let pointName: String
    let productID: String?
    let imageName: String
    let rewards: [BattlePassReward]
}

struct BattlePassReward: Decodable, Identifiable {
    let id: String
    let requiredPoints: Int
    let title: String
    let imageName: String
    let premium: Bool
    let rewards: [TradeResourceAmount]
}
