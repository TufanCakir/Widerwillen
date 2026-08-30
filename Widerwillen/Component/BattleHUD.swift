//
//  BattleHUD.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct BattleHUD: View {
    let progress: GameProgressStore
    let title: String
    let healthTitle: String
    let currentHP: Int
    let maxHP: Int

    var body: some View {
        VStack(spacing: 14) {
            GameHeader(progress: progress)

            VStack(spacing: 6) {
                Text(title)
                    .widerwillenFont(size: 22, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                healthBar
            }
            .padding(.horizontal, 52)
            .frame(maxWidth: .infinity)
        }
    }

    private var healthBar: some View {
        VStack(spacing: 5) {
            GeometryReader { proxy in
                let ratio = CGFloat(currentHP) / CGFloat(max(maxHP, 1))

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.black.opacity(0.58))

                    Rectangle()
                        .fill(.red)
                        .frame(width: proxy.size.width * min(max(ratio, 0), 1))
                }
            }
            .frame(height: 14)
            .overlay {
                Rectangle()
                    .stroke(.blue, lineWidth: 1)
            }

            HStack {
                Text(healthTitle)
                Spacer()
                Text("\(currentHP)/\(maxHP)")
            }
            .widerwillenFont(size: 10, weight: .bold)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }
}
