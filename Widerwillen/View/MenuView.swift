//
//  MenuView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct MenuView: View {
    let progress: GameProgressStore
    let openMode: (MenuMode) -> Void

    @State private var isModePickerPresented = false

    private let shortcutColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GameHeader(
                    progress: progress
                )

                Spacer()

                VStack(spacing: 28) {
                    Button {
                        isModePickerPresented = true
                    } label: {
                        Text("Start")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 0,
                                x: 1,
                                y: 1
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background {
                                Image("icon_pixel_menü")
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFill()
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    shortcutGrid
                }

                Spacer()
            }

            if isModePickerPresented {
                modePickerOverlay
            }
        }
        .background {
            AppBackground()
        }
    }

    private var shortcutGrid: some View {
        LazyVGrid(columns: shortcutColumns, spacing: 10) {
            shortcutButton(title: "Settings", assetImage: "icon_pixel_settings")
            {
                openMode(.settings)
            }
            shortcutButton(title: "News", assetImage: "icon_pixel_news") {
                openMode(.news)
            }
            shortcutButton(title: "Giftbox", assetImage: "icon_pixel_box") {
                openMode(.gift)
            }
            shortcutButton(
                title: "Daily Login",
                assetImage: "icon_pixel_calendar"
            ) {
                openMode(.dailyLogin)
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }

    private func shortcutButton(
        title: String,
        assetImage: String? = nil,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                if let assetImage {
                    Image(assetImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 28, weight: .heavy))
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .shadow(
            color: .black.opacity(0.9),
            radius: 0,
            x: 1,
            y: 1
        )
    }

    private var modePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    isModePickerPresented = false
                }

            VStack(spacing: 50) {
                popupButton(
                    title: "Battle",
                    iconImage: "icon_pixel_sword",
                    backgroundImage: "bg",
                    mode: .battle
                )
                popupButton(
                    title: "Events",
                    iconImage: "icon_pixel_sword",
                    backgroundImage: "bg",
                    mode: .event
                )
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 50)
            .background {
                AppBackground()
            }

            .clipShape(RoundedRectangle(cornerRadius: 42))
            .padding(.horizontal, 36)
        }
    }

    private func popupButton(
        title: String,
        iconImage: String,
        backgroundImage: String,
        mode: MenuMode
    ) -> some View {
        Button {
            isModePickerPresented = false
            openMode(mode)
        } label: {
            HStack(spacing: 20) {
                Image(iconImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 34, height: 34)

                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background {
                Image(backgroundImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .opacity(0.72)
            }
            .overlay {
                Capsule()
                    .stroke(.white, lineWidth: 2)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

enum MenuMode {
    case battle
    case event
    case settings
    case news
    case gift
    case dailyLogin
}

#Preview {
    MenuView(progress: GameProgressStore()) { _ in }
}
