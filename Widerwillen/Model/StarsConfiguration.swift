//
//  StarsConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation
import SwiftUI

struct StarsConfiguration: Decodable {
    let maxStars: Int
    let filledSystemImage: String
    let emptySystemImage: String
    let tiers: [StarTier]

    static func load(named resourceName: String = "stars") throws
        -> StarsConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    static var fallback: StarsConfiguration {
        StarsConfiguration(
            maxStars: 14,
            filledSystemImage: "star.fill",
            emptySystemImage: "star",
            tiers: [
                StarTier(
                    minStars: 1,
                    color: RGBColor(red: 1, green: 0.86, blue: 0.1)
                ),
                StarTier(
                    minStars: 8,
                    color: RGBColor(red: 0.42, green: 0.9, blue: 1)
                ),
                StarTier(
                    minStars: 12,
                    color: RGBColor(red: 1, green: 0.28, blue: 0.78)
                ),
            ]
        )
    }

    func color(for stars: Int) -> Color {
        let tier =
            tiers
            .sorted { $0.minStars < $1.minStars }
            .last { $0.minStars <= stars }

        return tier?.color.swiftUIColor ?? .yellow
    }
}

struct StarTier: Decodable {
    let minStars: Int
    let color: RGBColor
}
