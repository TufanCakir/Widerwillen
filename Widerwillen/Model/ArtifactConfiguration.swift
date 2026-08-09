//
//  ArtifactConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation
import SwiftUI

struct ArtifactConfiguration: Decodable {
    let banner: ArtifactBanner

    static func load(named resourceName: String = "artifact") throws
        -> ArtifactConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct ArtifactBanner: Decodable {
    let id: String
    let title: String
    let bannerImageName: String
    let singleCost: Int
    let multiCost: Int
    let multiCount: Int
    let entries: [ArtifactEntry]
}

struct ArtifactEntry: Decodable, Identifiable {
    let id: String
    let name: String
    let imageName: String
    let rarity: SpriteRarity
    let damageBonus: Int
    let weight: Double
}

struct OwnedArtifact: Identifiable, Codable {
    var id: String { artifactID }

    let artifactID: String
    let name: String
    let imageName: String
    let rarity: SpriteRarity
    let damageBonus: Int
    let level: Int
}

struct ArtifactSummonResult: Identifiable {
    let id = UUID()
    let entry: ArtifactEntry
    let isDuplicate: Bool
    let level: Int
}
