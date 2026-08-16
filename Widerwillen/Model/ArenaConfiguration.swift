//
//  ArenaConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct ArenaConfiguration: Decodable {
    let floorHeightRatio: CGFloat
    let characterDepth: CGFloat
    let characterScale: CGFloat
    let characterXPosition: CGFloat
    let looks: [ArenaLook]

    static func load(named resourceName: String = "arena") throws
        -> ArenaConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct ArenaLook: Decodable {
    let name: String
    let groundImageName: String?
    let groundDarkening: Double
}

struct RGBColor: Decodable {
    let red: Double
    let green: Double
    let blue: Double

    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue)
    }
}
