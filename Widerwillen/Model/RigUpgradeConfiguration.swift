//
//  RigUpgradeConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct RigUpgradeConfiguration: Decodable {
    let parts: [RigUpgradePart]

    static func load(named resourceName: String = "rig_upgrades") throws
        -> RigUpgradeConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct RigUpgradePart: Decodable, Identifiable {
    let id: String
    let title: String
    let imageFallback: String
    let levels: [RigUpgradeLevel]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageFallback
        case maxLevel
        case effectColors
        case levels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        imageFallback = try container.decode(
            String.self,
            forKey: .imageFallback
        )

        let configuredLevels = try container.decode(
            [RigUpgradeLevel].self,
            forKey: .levels
        )
        let maxLevel = max(
            try container.decodeIfPresent(Int.self, forKey: .maxLevel)
                ?? configuredLevels.count,
            configuredLevels.count
        )
        let colors =
            try container.decodeIfPresent([String].self, forKey: .effectColors)
            ?? []

        guard
            let finalConfiguredLevel = configuredLevels.max(by: {
                $0.level < $1.level
            })
        else {
            levels = []
            return
        }

        levels = (1...maxLevel).map { level in
            if let configured = configuredLevels.first(where: {
                $0.level == level
            }) {
                return configured.withColor(
                    Self.effectColor(
                        for: level,
                        maxLevel: maxLevel,
                        colors: colors
                    )
                )
            }

            let extraLevel = level - finalConfiguredLevel.level
            let cost = Int(
                (Double(finalConfiguredLevel.cost)
                    * pow(1.16, Double(extraLevel))).rounded()
            )

            return RigUpgradeLevel(
                level: level,
                cost: cost,
                glowIntensity: min(
                    3.2,
                    finalConfiguredLevel.glowIntensity + Double(extraLevel)
                        * 0.075
                ),
                particleBirthRate: min(
                    120,
                    finalConfiguredLevel.particleBirthRate + Double(extraLevel)
                        * 3.2
                ),
                particleColorHex: Self.effectColor(
                    for: level,
                    maxLevel: maxLevel,
                    colors: colors
                )
            )
        }
    }

    private static func effectColor(
        for level: Int,
        maxLevel: Int,
        colors: [String]
    ) -> String {
        guard !colors.isEmpty else { return "FFFFFF" }

        let progress = Double(max(level - 1, 0)) / Double(max(maxLevel - 1, 1))
        let index = min(Int(progress * Double(colors.count)), colors.count - 1)
        return colors[index]
    }
}

struct RigUpgradeLevel: Decodable, Identifiable {
    var id: Int { level }

    let level: Int
    let cost: Int
    let glowIntensity: Double
    let particleBirthRate: Double
    let particleColorHex: String

    init(
        level: Int,
        cost: Int,
        glowIntensity: Double,
        particleBirthRate: Double,
        particleColorHex: String
    ) {
        self.level = level
        self.cost = cost
        self.glowIntensity = glowIntensity
        self.particleBirthRate = particleBirthRate
        self.particleColorHex = particleColorHex
    }

    func withColor(_ color: String) -> RigUpgradeLevel {
        RigUpgradeLevel(
            level: level,
            cost: cost,
            glowIntensity: glowIntensity,
            particleBirthRate: particleBirthRate,
            particleColorHex: color
        )
    }

    private enum CodingKeys: String, CodingKey {
        case level
        case cost
        case glowIntensity
        case metalIntensity
        case particleBirthRate
        case particleColorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(Int.self, forKey: .level)
        cost = try container.decode(Int.self, forKey: .cost)
        glowIntensity =
            try container.decodeIfPresent(Double.self, forKey: .glowIntensity)
            ?? container.decodeIfPresent(Double.self, forKey: .metalIntensity)
            ?? 0
        particleBirthRate =
            try container.decodeIfPresent(
                Double.self,
                forKey: .particleBirthRate
            ) ?? 0
        particleColorHex =
            try container.decodeIfPresent(
                String.self,
                forKey: .particleColorHex
            ) ?? "FFFFFF"
    }
}
