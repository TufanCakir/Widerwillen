//
//  SkillConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct SkillConfiguration: Decodable {
    let skills: [SkillNode]

    static func load(named resourceName: String = "skill") throws
        -> SkillConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct SkillNode: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
    let imageName: String
    let effect: SkillEffect
    let valuePerLevel: Double
    let cost: Int
    let maxLevel: Int
}

enum SkillEffect: String, Codable {
    case damage
    case tapDamage
    case spriteDamage
    case attackSpeed
    case coinDrop
    case dropChance
    case prestigeRelics
}
