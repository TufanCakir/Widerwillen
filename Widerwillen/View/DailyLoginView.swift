//
//  DailyLoginView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct DailyLoginView: View {
    let progress: GameProgressStore

    private let configuration: DailyLoginConfiguration

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var selectedCategory = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        configuration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load()
    ) {
        self.progress = progress
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.logins.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            dailyBackground

            VStack(spacing: 12) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                CategoryBar(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    displayName: localizedCategory
                )

                if !message.isEmpty {
                    statusText(message)
                }

                TabView(selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        loginPage(for: category)
                            .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for login in configuration.logins where !values.contains(login.category)
        {
            values.append(login.category)
        }

        return values
    }

    private var selectedCampaigns: [DailyLoginCampaign] {
        configuration.logins.filter { $0.category == selectedCategory }
    }

    private var dailyBackground: some View {
        ZStack {
            RemoteImage(
                name: selectedCampaigns.first?.backgroundImageName ?? "bg_blue",
                contentMode: .fill
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.36), .black.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 92), spacing: 10)]
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private func localizedCategory(_ category: String) -> String {
        let key = configuration.logins.first { $0.category == category }?
            .categoryKey
        return localizer.text(key, fallback: category)
    }

    private func localizedTitle(_ login: DailyLoginCampaign) -> String {
        localizer.text(login.titleKey, fallback: login.title)
    }

    private func localizedTitle(_ reward: DailyLoginReward) -> String {
        localizer.text(reward.titleKey, fallback: reward.title)
    }

    private func loginPage(for category: String) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(configuration.logins.filter { $0.category == category })
                {
                    login in
                    loginSection(login)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 110)
        }
    }

    private func loginSection(_ login: DailyLoginCampaign) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedTitle(login))
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                Spacer()

                if progress.canClaimDailyLogin(for: login) {
                    Text(localizer.text("daily_login.ready", fallback: "Ready"))
                        .font(.system(size: 11, weight: .heavy))
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

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(login.rewards.sorted { $0.day < $1.day }) { reward in
                    rewardCard(reward, in: login)
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.46), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.85), radius: 4, x: 0, y: 3)
    }

    private func rewardCard(
        _ reward: DailyLoginReward,
        in login: DailyLoginCampaign
    ) -> some View {
        let currentReward = progress.currentDailyLoginReward(
            from: login.rewards
        )
        let isToday = currentReward?.day == reward.day
        let canClaim = isToday && progress.canClaimDailyLogin(for: login)

        return VStack(spacing: 7) {
            RemoteImage(name: reward.imageName)
                .frame(width: 38, height: 38)

            Text(localizedTitle(reward))
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

            ResourceAmountRow(
                amounts: reward.rewards,
                prefix: "+"
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 112)
        .padding(8)
        .background {
            RemoteImage(name: login.backgroundImageName, contentMode: .fill)
                .opacity(isToday ? 0.56 : 0.34)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    canClaim
                        ? .white.opacity(0.95)
                        : isToday
                            ? .white.opacity(0.68)
                            : .white.opacity(0.32),
                    lineWidth: canClaim ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.75), radius: 3, x: 0, y: 2)
        .opacity(isToday || progress.canClaimDailyLogin(for: login) ? 1 : 0.66)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            if canClaim {
                claim(reward, in: login)
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
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(.white.opacity(0.86))
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    DailyLoginView(progress: GameProgressStore())
}
