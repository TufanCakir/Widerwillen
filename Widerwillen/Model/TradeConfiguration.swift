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
    let costs: [TradeResourceAmount]
    let rewards: [TradeResourceAmount]
}

struct TradeResourceAmount: Decodable, Identifiable {
    var id: String { "\(resource.rawValue)-\(amount)" }

    let resource: TradeResource
    let amount: Int
}

enum TradeResource: String, Codable {
    case coins
    case crystals
    case relics

    var imageName: String {
        switch self {
        case .coins:
            "icon_pixel_coin"
        case .crystals:
            "icon_pixel_crystal"
        case .relics:
            "icon_pixel_relic"
        }
    }
}
