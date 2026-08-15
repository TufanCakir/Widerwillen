//
//  DailyLoginView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct DailyLoginView: View {
    let progress: GameProgressStore
    var onClose: (() -> Void)?

    private let configuration: DailyLoginConfiguration

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var selectedLoginID = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        configuration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load(),
        onClose: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.configuration = configuration
        self.onClose = onClose
        _selectedLoginID = State(
            initialValue: configuration.logins.first?.id ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    GameHeader(progress: progress)
                        .padding(.top, 18)

                    if let onClose {
                        Button {
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

    private var loginIDs: [String] {
        configuration.logins.map(\.id)
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 92), spacing: 10)]
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
            LazyVStack(spacing: 12) {
                loginSection(login)
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
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            ResourceAmountRow(
                amounts: reward.rewards,
                prefix: "+",
                color: .black
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 112)
        .padding(8)
        .background(.white.opacity(isToday ? 0.96 : 0.82))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    canClaim
                        ? .white.opacity(0.95)
                        : isToday
                            ? .black.opacity(0.32)
                            : .black.opacity(0.14),
                    lineWidth: canClaim ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.78), radius: 5, x: 0, y: 3)
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
