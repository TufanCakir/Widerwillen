//
//  Footer.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

enum AppTab: CaseIterable {
    case home
    case sprites
    case summon
    case shop
    case trade

    var title: String {
        switch self {
        case .home: "Home"
        case .sprites: "Sprite"
        case .summon: "Summon"
        case .shop: "Shop"
        case .trade: "Trade"
        }
    }

    var imageName: String {
        switch self {
        case .home: "icon_pixel_house"
        case .sprites: "icon_pixel_sprite"
        case .summon: "icon_pixel_crystal"
        case .shop: "icon_pixel_shop"
        case .trade: "icon_pixel_trade"
        }
    }

    var requiredAccountLevel: Int {
        switch self {
        case .home:
            1
        case .sprites:
            2
        case .summon:
            3
        case .trade:
            4
        case .shop:
            5
        }
    }
}

struct Footer: View {
    @Binding var selectedTab: AppTab
    let progress: GameProgressStore

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    guard isUnlocked(tab) else { return }
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        ZStack(alignment: .topTrailing) {
                            RemoteImage(name: tab.imageName)
                                .frame(width: 44, height: 44)
                                .clipped()

                            if !isUnlocked(tab) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(.black.opacity(0.58))
                                    .clipShape(Circle())
                                    .offset(x: 5, y: -2)
                            }
                        }

                        Text(isUnlocked(tab) ? tab.title : "LV \(tab.requiredAccountLevel)")
                            .font(.system(size: 10, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )

                    }
                    .foregroundStyle(.white)
                    .opacity(isUnlocked(tab) ? 1 : 0.48)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .padding(.horizontal)
    }

    private func isUnlocked(_ tab: AppTab) -> Bool {
        progress.accountLevel >= tab.requiredAccountLevel
    }
}

extension GameProgressStore {
    func canAccess(tab: AppTab) -> Bool {
        accountLevel >= tab.requiredAccountLevel
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        Footer(selectedTab: .constant(.home), progress: GameProgressStore())
    }
}
