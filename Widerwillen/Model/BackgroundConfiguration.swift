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
