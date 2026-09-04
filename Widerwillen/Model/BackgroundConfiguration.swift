//
//  BackgroundConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation
import SwiftUI

struct BackgroundConfiguration: Decodable {
    let looks: [GameBackgroundLook]

    static func load(named resourceName: String = "background") throws
        -> BackgroundConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct GameBackgroundLook: Decodable {
    let name: String
    let backgroundColor: RGBColor
    let backgroundImageName: String?
    let backgroundDarkening: Double
}

struct MenuBackgroundConfiguration: Decodable {
    let backgrounds: [MenuBackgroundDefinition]
    let buttonLooks: [MenuButtonLookDefinition]

    static let defaultBackgroundID = "app_background_default"
    static let defaultButtonLookID = "menu_button_default"

    static func load(named resourceName: String = "menuBackground") throws
        -> MenuBackgroundConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    static var fallback: MenuBackgroundConfiguration {
        MenuBackgroundConfiguration(
            backgrounds: [
                MenuBackgroundDefinition(
                    id: defaultBackgroundID,
                    title: "Widerwillen Rings",
                    imageName: nil,
                    usesAnimatedRings: true,
                    darkening: 0
                )
            ],
            buttonLooks: [
                MenuButtonLookDefinition(
                    id: defaultButtonLookID,
                    title: "Default",
                    imageName: nil
                )
            ]
        )
    }
}

struct MenuBackgroundDefinition: Decodable, Identifiable {
    let id: String
    let title: String
    let imageName: String?
    let usesAnimatedRings: Bool
    let darkening: Double
}

struct MenuButtonLookDefinition: Decodable, Identifiable {
    let id: String
    let title: String
    let imageName: String?
}
