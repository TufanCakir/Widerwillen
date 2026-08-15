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

    private let dailyLoginConfiguration: DailyLoginConfiguration

    @State private var isModePickerPresented = false
    @State private var isDailyLoginPopupPresented = false
    @State private var didEvaluateDailyLoginPopup = false

    init(
        progress: GameProgressStore,
        dailyLoginConfiguration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load(),
        openMode: @escaping (MenuMode) -> Void
    ) {
        self.progress = progress
        self.dailyLoginConfiguration = dailyLoginConfiguration
        self.openMode = openMode
    }

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
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background {
                                RemoteImage(
                                    name: "icon_pixel_menü",
                                    contentMode: .fill
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    shortcutGrid
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 24)

                Spacer()
            }

            if isModePickerPresented {
                modePickerOverlay
            }

            if isDailyLoginPopupPresented {
                dailyLoginPopup
            }

        }
        .background {
            AppBackground()
        }
        .onAppear {
            showDailyLoginPopupIfNeeded()
        }
    }

    private var shortcutGrid: some View {
        LazyVGrid(columns: shortcutColumns, spacing: 10) {
            shortcutButton(title: "Settings", assetImage: "icon_pixel_settings")
            {
                openMode(.settings)
            }
            shortcutButton(title: "Skills", assetImage: "icon_pixel_relic") {
                openMode(.skills)
            }
            shortcutButton(title: "News", assetImage: "icon_pixel_news") {
                openMode(.news)
            }
            shortcutButton(title: "Giftbox", assetImage: "icon_pixel_giftbox") {
                openMode(.gift)
            }
            shortcutButton(title: "Warehouse", assetImage: "icon_pixel_box") {
                openMode(.warehouse)
            }
            shortcutButton(title: "Pass", assetImage: "icon_pixel_relic") {
                openMode(.pass)
            }
            shortcutButton(
                title: "Daily Login",
                assetImage: "icon_pixel_calendar"
            ) {
                openMode(.dailyLogin)
            }
        }
        .padding(.top, 50)
    }

    private var claimableDailyLogins: [DailyLoginCampaign] {
        dailyLoginConfiguration.logins.filter {
            progress.canClaimDailyLogin(for: $0)
        }
    }

    private func shortcutButton(
        title: String,
        assetImage: String? = nil,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 10) {
                if let assetImage {
                    RemoteImage(name: assetImage)
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
            radius: 3,
            x: 0,
            y: 0
        )
    }

    private var modePickerOverlay: some View {
        ZStack {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    isModePickerPresented = false
                }
            } label: {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .zIndex(0)

            VStack(spacing: 22) {
                popupButton(
                    title: "Battle",
                    iconImage: "icon_pixel_sword",
                    backgroundImage: "bg_app",
                    mode: .battle
                )
                popupButton(
                    title: "Events",
                    iconImage: "icon_pixel_sword",
                    backgroundImage: "bg_app",
                    mode: .event
                )
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background {
                RemoteImage(name: "bg_app", contentMode: .fill)
                    .opacity(0.88)
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.72), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 36)
            .zIndex(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dailyLoginPopup: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()

            DailyLoginView(
                progress: progress,
                configuration: dailyLoginConfiguration,
                isCompactPresentation: true
            ) {
                withAnimation(.snappy(duration: 0.2)) {
                    isDailyLoginPopupPresented = false
                }
            }
            .frame(maxWidth: 360)
            .frame(maxHeight: 560)
            .background(.black.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.64), lineWidth: 1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 44)
            .shadow(color: .black.opacity(0.92), radius: 10, x: 0, y: 5)
        }
        .zIndex(20)
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
                RemoteImage(name: iconImage)
                    .frame(width: 34, height: 34)

                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background {
                RemoteImage(name: backgroundImage, contentMode: .fill)
                    .opacity(0.72)
            }
            .overlay {
                Capsule()
                    .stroke(.white, lineWidth: 2)
            }
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func showDailyLoginPopupIfNeeded() {
        guard !didEvaluateDailyLoginPopup else { return }
        didEvaluateDailyLoginPopup = true

        guard !claimableDailyLogins.isEmpty else { return }

        withAnimation(.snappy(duration: 0.24)) {
            isDailyLoginPopupPresented = true
        }
    }
}

enum MenuMode {
    case battle
    case event
    case skills
    case settings
    case news
    case gift
    case warehouse
    case pass
    case dailyLogin
}

#Preview {
    MenuView(progress: GameProgressStore()) { _ in }
}
