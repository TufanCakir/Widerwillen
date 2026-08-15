//
//  EnemyConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct EnemyConfiguration: Decodable {
    let areas: [EnemyArea]

    static func load(named resourceName: String = "enemies") throws
        -> EnemyConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    func enemy(for stage: Int) -> EnemyDefinition {
        let safeStage = max(stage, 1)
        let area = area(for: safeStage)
        let list = safeStage.isMultiple(of: 10) ? area.bosses : area.enemies
        let fallbackList = list.isEmpty ? area.enemies : list

        guard !fallbackList.isEmpty else {
            return EnemyDefinition(
                id: "fallback_enemy",
                name: "Enemy",
                imageName: "sprite_blunt",
                scale: 0.30,
                animationID: "sprite_blunt",
                columns: 1,
                rows: 1,
                frameCount: 1,
                fps: 8
            )
        }

        return fallbackList[(safeStage - 1) % fallbackList.count]
    }

    func area(for stage: Int) -> EnemyArea {
        guard !areas.isEmpty else {
            return EnemyArea(
                id: "fallback_area",
                name: "Arena",
                startsAtStage: 1,
                transitionImageName: "bg_app",
                enemies: [],
                bosses: []
            )
        }

        let safeStage = max(stage, 1)
        return
            areas
            .sorted { $0.startsAtStage < $1.startsAtStage }
            .last { $0.startsAtStage <= safeStage } ?? areas[0]
    }
}

struct EnemyArea: Decodable, Identifiable {
    let id: String
    let name: String
    let startsAtStage: Int
    let transitionImageName: String
    let enemies: [EnemyDefinition]
    let bosses: [EnemyDefinition]
}

struct EnemyDefinition: Decodable, Identifiable {
    let id: String
    let name: String
    let imageName: String
    let scale: Double
    let animationID: String?
    let columns: Int?
    let rows: Int?
    let frameCount: Int?
    let fps: Double?

    init(
        id: String,
        name: String,
        imageName: String,
        scale: Double,
        animationID: String? = nil,
        columns: Int? = nil,
        rows: Int? = nil,
        frameCount: Int? = nil,
        fps: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.scale = scale
        self.animationID = animationID
        self.columns = columns
        self.rows = rows
        self.frameCount = frameCount
        self.fps = fps
    }
}
