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

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var isModePickerPresented = false
    @State private var isDailyLoginPopupPresented = false
    @State private var didEvaluateDailyLoginPopup = false
    @State private var selectedDailyLoginID = ""

    init(
        progress: GameProgressStore,
        dailyLoginConfiguration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load(),
        openMode: @escaping (MenuMode) -> Void
    ) {
        self.progress = progress
        self.dailyLoginConfiguration = dailyLoginConfiguration
        self.openMode = openMode
        _selectedDailyLoginID = State(
            initialValue: dailyLoginConfiguration.logins.first?.id ?? ""
        )
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

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private var claimableDailyLogins: [DailyLoginCampaign] {
        dailyLoginConfiguration.logins.filter {
            progress.canClaimDailyLogin(for: $0)
        }
    }

    private var selectedDailyLogin: DailyLoginCampaign? {
        claimableDailyLogins.first { $0.id == selectedDailyLoginID }
            ?? claimableDailyLogins.first
    }

    private func shortcutButton(
        title: String,
        assetImage: String? = nil,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        let requiredLevel = requiredAccountLevel(for: title)
        let isUnlocked = progress.accountLevel >= requiredLevel

        return Button {
            guard isUnlocked else { return }
            action()
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    if let assetImage {
                        RemoteImage(name: assetImage)
                            .frame(width: 32, height: 32)
                    } else if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 28, weight: .heavy))
                    }

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(3)
                            .background(.black.opacity(0.58))
                            .clipShape(Circle())
                            .offset(x: 7, y: -5)
                    }
                }

                Text(isUnlocked ? title : "LV \(requiredLevel)")
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .opacity(isUnlocked ? 1 : 0.48)
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

            VStack(spacing: 12) {
                HStack {
                    Text(
                        localizer.text(
                            "daily_login.popup.title",
                            fallback: "Daily Bonus"
                        )
                    )
                    .font(.system(size: 20, weight: .heavy))

                    Spacer()

                    Button {
                        isDailyLoginPopupPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }

                if claimableDailyLogins.count > 1 {
                    Picker("", selection: $selectedDailyLoginID) {
                        ForEach(claimableDailyLogins) { login in
                            Text(localizedTitle(login))
                                .tag(login.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.white)
                }

                if let login = selectedDailyLogin,
                    let reward = progress.currentDailyLoginReward(
                        from: login.rewards
                    )
                {
                    dailyLoginPopupCard(reward, in: login)
                }

                HStack(spacing: 10) {
                    Button {
                        isDailyLoginPopupPresented = false
                        openMode(.dailyLogin)
                    } label: {
                        Text(
                            localizer.text(
                                "daily_login.popup.open",
                                fallback: "Open"
                            )
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button {
                        claimSelectedDailyLoginReward()
                    } label: {
                        Text(
                            localizer.text(
                                "daily_login.popup.claim",
                                fallback: "Claim"
                            )
                        )
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(
                            color: .black.opacity(0.85),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(14)
            .frame(maxWidth: 330)
            .background(.black.opacity(0.82))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.66), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.92), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
        }
        .zIndex(20)
    }

    private func dailyLoginPopupCard(
        _ reward: DailyLoginReward,
        in login: DailyLoginCampaign
    ) -> some View {
        HStack(spacing: 12) {
            RemoteImage(name: reward.imageName)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(localizedTitle(login))
                    .font(.system(size: 12, weight: .heavy))
                    .opacity(0.76)

                Text(localizedTitle(reward))
                    .font(.system(size: 18, weight: .heavy))

                ResourceAmountRow(amounts: reward.rewards, prefix: "+")
            }

            Spacer()
        }
        .padding(12)
        .background {
            RemoteImage(name: login.backgroundImageName, contentMode: .fill)
                .opacity(0.72)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func popupButton(
        title: String,
        iconImage: String,
        backgroundImage: String,
        mode: MenuMode
    ) -> some View {
        let requiredLevel = mode.requiredAccountLevel
        let isUnlocked = progress.accountLevel >= requiredLevel

        return Button {
            guard isUnlocked else { return }
            isModePickerPresented = false
            openMode(mode)
        } label: {
            HStack(spacing: 20) {
                RemoteImage(name: iconImage)
                    .frame(width: 34, height: 34)

                Text(isUnlocked ? title : "\(title) LV \(requiredLevel)")
                    .font(.system(size: 24, weight: .bold))
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .heavy))
                }
            }
            .foregroundStyle(.white)
            .opacity(isUnlocked ? 1 : 0.5)
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

    private func requiredAccountLevel(for shortcutTitle: String) -> Int {
        switch shortcutTitle {
        case "Skills":
            2
        case "Warehouse":
            2
        case "Pass":
            2
        case "Giftbox":
            2
        case "News":
            2
        default:
            1
        }
    }

    private func showDailyLoginPopupIfNeeded() {
        guard !didEvaluateDailyLoginPopup else { return }
        didEvaluateDailyLoginPopup = true

        guard let firstLogin = claimableDailyLogins.first else { return }
        selectedDailyLoginID = firstLogin.id

        withAnimation(.snappy(duration: 0.24)) {
            isDailyLoginPopupPresented = true
        }
    }

    private func claimSelectedDailyLoginReward() {
        guard let login = selectedDailyLogin,
            let reward = progress.currentDailyLoginReward(from: login.rewards)
        else {
            isDailyLoginPopupPresented = false
            return
        }

        _ = progress.claimDailyLoginReward(reward, in: login)

        if let nextLogin = claimableDailyLogins.first {
            selectedDailyLoginID = nextLogin.id
        } else {
            withAnimation(.snappy(duration: 0.2)) {
                isDailyLoginPopupPresented = false
            }
        }
    }

    private func localizedTitle(_ login: DailyLoginCampaign) -> String {
        localizer.text(login.titleKey, fallback: login.title)
    }

    private func localizedTitle(_ reward: DailyLoginReward) -> String {
        localizer.text(reward.titleKey, fallback: reward.title)
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

    var requiredAccountLevel: Int {
        switch self {
        case .battle, .settings, .dailyLogin:
            1
        case .skills, .news, .gift, .warehouse, .pass:
            2
        case .event:
            3
        }
    }
}

#Preview {
    MenuView(progress: GameProgressStore()) { _ in }
}
