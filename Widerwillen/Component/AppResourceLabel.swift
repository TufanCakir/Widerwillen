//
//  AppResourceLabel.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct AppResourceLabel: View {

    let imageName: String
    let value: Double

    var prefix = ""
    var iconSize: CGFloat = 28
    var fontSize: CGFloat = 13
    var color: Color = .white

    var body: some View {
        HStack(spacing: 6) {

            RemoteImage(name: imageName)
                .frame(width: iconSize, height: iconSize)

            Text("\(prefix)\(value.abbreviatedResourceText)")
                .widerwillenFont(size: fontSize, weight: .bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(color)
        .shadow(
            color: .black.opacity(0.9),
            radius: 3
        )
    }
}

extension Double {

    var abbreviatedResourceText: String {

        let amount = abs(self)
        let sign = self < 0 ? "-" : ""

        let units: [(value: Double, suffix: String)] = [
            (1e63, "Vg"),
            (1e60, "Nd"),
            (1e57, "Od"),
            (1e54, "Sp"),
            (1e51, "Sx"),
            (1e48, "QiD"),
            (1e45, "QaD"),
            (1e42, "Td"),
            (1e39, "Dd"),
            (1e36, "Ud"),
            (1e33, "Dc"),
            (1e30, "No"),
            (1e27, "Oc"),
            (1e24, "Sp"),
            (1e21, "Sx"),
            (1e18, "Qi"),
            (1e15, "Qa"),
            (1e12, "T"),
            (1e9, "B"),
            (1e6, "M"),
            (1e3, "K"),
        ]

        guard
            let unit = units.first(where: {
                amount >= $0.value
            })
        else {
            return Self.cleanNumber(amount, sign: sign)
        }

        let shortened = amount / unit.value

        return sign
            + Self.format(shortened)
            + unit.suffix
    }

    private static func format(_ value: Double) -> String {

        let text: String

        switch value {

        case 100...:
            text = String(format: "%.0f", value)

        case 10...:
            text = String(format: "%.1f", value)

        default:
            text = String(format: "%.2f", value)
        }

        return
            text
            .replacingOccurrences(of: ".00", with: "")
            .replacingOccurrences(of: ".0", with: "")
    }

    private static func cleanNumber(
        _ value: Double,
        sign: String
    ) -> String {

        if value.rounded() == value {
            return sign + String(format: "%.0f", value)
        }

        return sign + Self.format(value)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GameHeader(
            progress: GameProgressStore()
        )
    }
}
