//
//  SkillConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct SkillConfiguration: Decodable {
    let trees: [SkillTreeDefinition]
    let skills: [SkillNode]

    private enum CodingKeys: String, CodingKey {
        case trees
        case skills
    }

    init(trees: [SkillTreeDefinition] = [], skills: [SkillNode]) {
        self.trees = trees
        self.skills = skills
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trees =
            try container.decodeIfPresent(
                [SkillTreeDefinition].self,
                forKey: .trees
            ) ?? []
        skills = try container.decode([SkillNode].self, forKey: .skills)
    }

    static func load(named resourceName: String = "skill") throws
        -> SkillConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct SkillTreeDefinition: Decodable, Identifiable {
    var id: String { category }

    let category: String
    let title: String
    let backgroundImageName: String
    let requiredAccountLevel: Int
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
    let requiredAccountLevel: Int?
    let activation: SkillActivation?
}

enum SkillEffect: String, Codable {
    case damage
    case tapDamage
    case spriteDamage
    case attackSpeed
    case coinDrop
    case dropChance
    case prestigeRelics
    case activeSkillDuration
    case activeSkillCooldown
    case stageSkipChance
}

struct SkillActivation: Decodable {
    let kind: ActiveSkillKind
    let durationSeconds: Double
    let cooldownSeconds: Double
    let damageMultiplier: Double
    let intervalSeconds: Double
    let companionAnimationID: String?
}

enum ActiveSkillKind: String, Codable {
    case shadowClone
}
