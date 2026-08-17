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
}

struct Footer: View {
    @Binding var selectedTab: AppTab
    let progress: GameProgressStore
    var playSoundEffect: (String) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    playSoundEffect(
                        selectedTab == tab ? "ui_tap" : "ui_navigation"
                    )
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        RemoteImage(name: tab.imageName)
                            .frame(width: 44, height: 44)
                            .clipped()

                        Text(tab.title)
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
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackground()
        Footer(selectedTab: .constant(.home), progress: GameProgressStore())
    }
}
