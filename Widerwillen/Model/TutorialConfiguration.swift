//
//  TutorialConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import Foundation

struct TutorialConfiguration: Decodable {
    let tutorials: [TutorialDefinition]

    static func load(named resourceName: String = "tutorial") throws
        -> TutorialConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct TutorialDefinition: Decodable, Identifiable {
    let id: String
    let trigger: TutorialTrigger
    let requiredAccountLevel: Int
    let speakerName: String
    let speakerNameKey: String?
    let speakerImageName: String
    let title: String
    let titleKey: String?
    let messages: [String]
    let messageKeys: [String]?
}

enum TutorialTrigger: String, Codable {
    case launch
    case battle
    case sprites
    case summon
    case skills
    case shop
    case trade
    case event
    case warehouse
    case settings
    case news
    case gift
    case dailyLogin
}
