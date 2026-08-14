//
//  CompanionConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct CompanionConfiguration: Decodable {
    let companions: [CompanionDefinition]

    static func load(named resourceName: String = "companion") throws
        -> CompanionConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    func companion(id: String) -> CompanionDefinition? {
        companions.first { $0.id == id }
    }

    func companion(spriteIndex: Int) -> CompanionDefinition? {
        companions.first { $0.legacySpriteIndex == spriteIndex }
    }
}

struct CompanionDefinition: Decodable, Identifiable {
    let id: String
    let name: String
    let imageName: String
    let animationID: String
    let rarity: SpriteRarity
    let baseDPS: Int
    let maxStars: Int
    let legacySpriteIndex: Int?
}
