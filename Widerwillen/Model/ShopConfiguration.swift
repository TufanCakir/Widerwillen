//
//  ShopConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct ShopConfiguration: Decodable {
    let categories: [ShopCategory]
    let crystalPacks: [CrystalPack]
    let characterPacks: [CharacterPack]

    init(
        categories: [ShopCategory] = [],
        crystalPacks: [CrystalPack],
        characterPacks: [CharacterPack] = []
    ) {
        self.categories = categories
        self.crystalPacks = crystalPacks
        self.characterPacks = characterPacks
    }

    static func load(named resourceName: String = "shop") throws
        -> ShopConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    var allProductIDs: [String] {
        crystalPacks.map(\.productID) + characterPacks.map(\.productID)
    }
}

struct ShopCategory: Decodable, Identifiable {
    let id: String
    let title: String
    let imageName: String
}

struct CrystalPack: Decodable, Identifiable {
    let id: String
    let category: String
    let purchaseType: ShopPurchaseType
    let productID: String
    let title: String
    let subtitle: String?
    let crystalAmount: Int
    let bonusCrystals: Int
    let imageName: String
    let limitedUntil: String?

    var totalCrystals: Int {
        crystalAmount + bonusCrystals
    }
}

struct CharacterPack: Decodable, Identifiable {
    let id: String
    let category: String
    let purchaseType: ShopPurchaseType
    let productID: String
    let title: String
    let subtitle: String?
    let imageName: String
    let characterIDs: [String]
    let skinIDs: [String]
    let bonusCrystals: Int
    let rewards: [TradeResourceAmount]
    let limitedUntil: String?
}

enum ShopPurchaseType: String, Codable {
    case consumable
    case nonConsumable
}
