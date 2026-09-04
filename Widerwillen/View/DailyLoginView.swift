//
//  DailyLoginView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct DailyLoginView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void
    var isCompactPresentation = false
    var onClose: (() -> Void)?

    private let configuration: DailyLoginConfiguration

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var selectedLoginID = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        configuration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load(),
        isCompactPresentation: Bool = false,
        onClose: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.configuration = configuration
        self.isCompactPresentation = isCompactPresentation
        self.onClose = onClose
        _selectedLoginID = State(
            initialValue: configuration.logins.first?.id ?? ""
        )
    }

    var body: some View {
        if isCompactPresentation {
            compactBody
        } else {
            fullBody
        }
    }

    private var fullBody: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    GameHeader(progress: progress)
                        .padding(.top, 18)

                    if let onClose {
                        Button {
                            playSoundEffect("ui_back")
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(.black.opacity(0.58))
                                .clipShape(Circle())
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 50)
                        .padding(.trailing, 18)
                    }
                }

                CategoryBar(
                    categories: loginIDs,
                    selectedCategory: $selectedLoginID,
                    playSoundEffect: playSoundEffect,
                    displayName: localizedLoginTitle
                )

                if !message.isEmpty {
                    statusText(message)
                }

                TabView(selection: $selectedLoginID) {
                    ForEach(configuration.logins) { login in
                        loginPage(for: login)
                            .tag(login.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private var compactBody: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text(localizer.text("daily_login.title", fallback: "Daily Login"))
                    .widerwillenFont(size: 20, weight: .heavy)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let onClose {
                    Button {
                        playSoundEffect("ui_back")
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.black.opacity(0.58))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            if !message.isEmpty {
                statusText(message)
                    .frame(height: 20)
            }

            HStack(alignment: .top, spacing: 8) {
                compactLoginTabs

                compactLoginPage
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background {
            compactPopupBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var loginIDs: [String] {
        configuration.logins.map(\.id)
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: isCompactPresentation ? 64 : 78),
                spacing: isCompactPresentation ? 6 : 8
            )
        ]
    }

    private var compactColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: 3
        )
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private func localizedLoginTitle(_ id: String) -> String {
        guard let login = configuration.logins.first(where: { $0.id == id })
        else {
            return id
        }

        return localizedTitle(login)
    }

    private func localizedTitle(_ login: DailyLoginCampaign) -> String {
        localizer.text(login.titleKey, fallback: login.title)
    }

    private func localizedTitle(_ reward: DailyLoginReward) -> String {
        localizer.text(reward.titleKey, fallback: reward.title)
    }

    private func loginPage(for login: DailyLoginCampaign) -> some View {
        ScrollView {
            LazyVStack(spacing: isCompactPresentation ? 6 : 10) {
                loginSection(login)
            }
            .padding(.horizontal, isCompactPresentation ? 8 : 12)
            .padding(.bottom, isCompactPresentation ? 14 : 110)
        }
    }

    private var selectedLogin: DailyLoginCampaign? {
        configuration.logins.first { $0.id == selectedLoginID }
            ?? configuration.logins.first
    }

    private var compactPopupBackground: some View {
        ZStack {
            if let selectedLogin {
                RemoteImage(name: selectedLogin.backgroundImageName, contentMode: .fill)
                    .opacity(0.52)
            }

            LinearGradient(
                colors: [
                    .black.opacity(0.58),
                    .black.opacity(0.22),
                    .black.opacity(0.64)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var compactLoginTabs: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(configuration.logins) { login in
                    compactLoginTab(login)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(width: 92)
    }

    private func compactLoginTab(_ login: DailyLoginCampaign) -> some View {
        let isSelected = selectedLoginID == login.id
        let canClaim = progress.canClaimDailyLogin(for: login)

        return Button {
            playSoundEffect("ui_select")
            withAnimation(.snappy(duration: 0.18)) {
                selectedLoginID = login.id
            }
        } label: {
            VStack(spacing: 5) {
                Text(localizedTitle(login))
                    .widerwillenFont(size: 9, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.62)
                    .frame(width: 74, height: 28)

                if canClaim {
                    Text(localizer.text("daily_login.ready", fallback: "Ready"))
                        .widerwillenFont(size: 8, weight: .heavy)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 7)
                        .frame(height: 18)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(width: 86, height: 68)
            .background(isSelected ? .blue.opacity(0.48) : .black.opacity(0.42))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? .white.opacity(0.92) : .blue.opacity(0.72),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.65), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var compactLoginPage: some View {
        ScrollView {
            if let selectedLogin {
                LazyVGrid(columns: compactColumns, spacing: 8) {
                    ForEach(selectedLogin.rewards.sorted { $0.day < $1.day }) {
                        reward in
                        compactRewardCard(reward, in: selectedLogin)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loginSection(_ login: DailyLoginCampaign) -> some View {
        VStack(alignment: .leading, spacing: isCompactPresentation ? 7 : 9) {
            HStack {
                Text(localizedTitle(login))
                    .font(
                        .system(
                            size: isCompactPresentation ? 15 : 18,
                            weight: .heavy
                        )
                    )
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                Spacer()

                if progress.canClaimDailyLogin(for: login) {
                    Text(localizer.text("daily_login.ready", fallback: "Ready"))
                        .widerwillenFont(size: 11, weight: .heavy)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 9)
                        .frame(height: 24)
                        .background(.white)
                        .clipShape(Capsule())
                        .shadow(
                            color: .black.opacity(0.7),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                }
            }

            LazyVGrid(columns: columns, spacing: isCompactPresentation ? 6 : 8)
            {
                ForEach(login.rewards.sorted { $0.day < $1.day }) { reward in
                    rewardCard(reward, in: login)
                }
            }
        }
        .padding(isCompactPresentation ? 8 : 10)
        .background {
            ZStack {
                RemoteImage(name: login.backgroundImageName, contentMode: .fill)
                    .opacity(0.74)

                LinearGradient(
                    colors: [.black.opacity(0.18), .black.opacity(0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.85), radius: 4, x: 0, y: 3)
    }

    private func rewardCard(
        _ reward: DailyLoginReward,
        in login: DailyLoginCampaign
    ) -> some View {
        let currentReward = progress.currentDailyLoginReward(in: login)
        let isToday = currentReward?.day == reward.day
        let canClaim = isToday && progress.canClaimDailyLogin(for: login)
        let isClaimed = isToday && !progress.canClaimDailyLogin(for: login)

        return VStack(spacing: isCompactPresentation ? 4 : 5) {
            RemoteImage(name: reward.imageName)
                .frame(
                    width: isCompactPresentation ? 24 : 30,
                    height: isCompactPresentation ? 24 : 30
                )
                .saturation(isClaimed ? 0 : 1)
                .opacity(isClaimed ? 0.45 : 1)

            Text(localizedTitle(reward))
                .font(
                    .system(
                        size: isCompactPresentation ? 9 : 10,
                        weight: .heavy
                    )
                )
                .foregroundStyle(isClaimed ? .black.opacity(0.48) : .black)
                .strikethrough(isClaimed, color: .black.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            ResourceAmountRow(
                amounts: reward.rewards,
                prefix: "+",
                color: isClaimed ? .black.opacity(0.48) : .black,
                iconSize: isCompactPresentation ? 13 : 15,
                fontSize: isCompactPresentation ? 8 : 9
            )
            .strikethrough(isClaimed, color: .black.opacity(0.65))

            if !reward.unlocks.isEmpty {
                unlockPreviewRow(
                    reward.unlocks,
                    color: isClaimed ? .black.opacity(0.48) : .black
                )
                .strikethrough(isClaimed, color: .black.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(
            height: reward.unlocks.isEmpty
                ? (isCompactPresentation ? 76 : 92)
                : (isCompactPresentation ? 94 : 108)
        )
        .padding(isCompactPresentation ? 5 : 6)
        .background(
            isClaimed
                ? .gray.opacity(0.76)
                : .white.opacity(isToday ? 0.96 : 0.82)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    canClaim ? .white.opacity(0.95) : .blue,
                    lineWidth: canClaim ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.78), radius: 5, x: 0, y: 3)
        .opacity(isToday || progress.canClaimDailyLogin(for: login) ? 1 : 0.62)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            if canClaim {
                playSoundEffect("ui_confirm")
                claim(reward, in: login)
            } else {
                playSoundEffect("ui_tap")
            }
        }
    }

    private func compactRewardCard(
        _ reward: DailyLoginReward,
        in login: DailyLoginCampaign
    ) -> some View {
        let currentReward = progress.currentDailyLoginReward(in: login)
        let isToday = currentReward?.day == reward.day
        let canClaim = isToday && progress.canClaimDailyLogin(for: login)
        let isClaimed = isToday && !progress.canClaimDailyLogin(for: login)
        let firstReward = reward.rewards.first

        return VStack(spacing: 5) {
            Text("D\(reward.day)")
                .widerwillenFont(size: 10, weight: .heavy)
                .foregroundStyle(isClaimed ? .white.opacity(0.42) : .white)
                .lineLimit(1)

            RemoteImage(name: reward.imageName)
                .frame(width: 24, height: 24)
                .saturation(isClaimed ? 0 : 1)
                .opacity(isClaimed ? 0.42 : 1)

            if let firstReward {
                AppResourceLabel(
                    imageName: firstReward.imageName
                        ?? firstReward.resource.imageName,
                    value: firstReward.amount,
                    prefix: "+",
                    iconSize: 11,
                    fontSize: 8,
                    color: isClaimed ? .white.opacity(0.42) : .white
                )
            } else if let unlock = reward.unlocks.first {
                Text(unlock.name)
                    .widerwillenFont(size: 8, weight: .heavy)
                    .foregroundStyle(isClaimed ? .white.opacity(0.42) : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .padding(.horizontal, 5)
        .background(canClaim ? .blue.opacity(0.38) : .black.opacity(0.32))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    canClaim ? .white.opacity(0.95) : .blue.opacity(0.72),
                    lineWidth: canClaim ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isToday || progress.canClaimDailyLogin(for: login) ? 1 : 0.62)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            if canClaim {
                playSoundEffect("ui_confirm")
                claim(reward, in: login)
            } else {
                playSoundEffect("ui_tap")
            }
        }
    }

    private func unlockPreviewRow(
        _ unlocks: [TradeUnlockReward],
        color: Color
    ) -> some View {
        HStack(spacing: 5) {
            ForEach(unlocks) { unlock in
                HStack(spacing: 4) {
                    RemoteImage(name: unlock.imageName)
                        .frame(
                            width: isCompactPresentation ? 12 : 14,
                            height: isCompactPresentation ? 12 : 14
                        )

                    Text(unlock.name)
                        .font(
                            .system(
                                size: isCompactPresentation ? 7 : 8,
                                weight: .heavy
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .foregroundStyle(color)
            }
        }
    }

    private func claim(
        _ reward: DailyLoginReward,
        in login: DailyLoginCampaign
    ) {
        message =
            progress.claimDailyLoginReward(reward, in: login)
            ? localizer.text(
                "daily_login.claimed",
                fallback: "Daily reward claimed"
            )
            : localizer.text(
                "daily_login.already_claimed",
                fallback: "Already claimed today"
            )

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { message = "" }
        }
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .widerwillenFont(size: 13, weight: .heavy)
            .foregroundStyle(.white.opacity(0.86))
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    DailyLoginView(progress: GameProgressStore())
}
