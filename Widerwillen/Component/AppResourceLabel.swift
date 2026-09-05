//
//  AppResourceLabel.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct AppResourceLabel: View {
    let imageName: String
    let value: Int
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
            radius: 3,
            x: 0,
            y: 0
        )
    }
}

extension Int {
    var abbreviatedResourceText: String {
        let sign = self < 0 ? "-" : ""
        let amount = abs(self)

        switch amount {
        case 1_000_000_000...:
            return sign
                + Self.abbreviated(
                    amount,
                    divisor: 1_000_000_000,
                    suffix: "bil"
                )
        case 1_000_000...:
            return sign
                + Self.abbreviated(amount, divisor: 1_000_000, suffix: "mil")
        case 1_000...:
            return sign + Self.abbreviated(amount, divisor: 1_000, suffix: "k")
        default:
            return "\(self)"
        }
    }

    private static func abbreviated(_ amount: Int, divisor: Int, suffix: String)
        -> String
    {
        let value = Double(amount) / Double(divisor)
        let text: String

        if value >= 100 {
            text = String(format: "%.0f", value)
        } else if value >= 10 {
            text = String(format: "%.1f", value)
        } else {
            text = String(format: "%.2f", value)
        }

        return
            text
            .replacingOccurrences(of: ".00", with: "")
            .replacingOccurrences(of: ".0", with: "")
            + suffix
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
