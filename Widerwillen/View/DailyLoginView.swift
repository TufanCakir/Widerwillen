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
        ZStack {
            if !isCompactPresentation {
                AppBackground()
            }

            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    if isCompactPresentation {
                        Text(
                            localizer.text(
                                "daily_login.title",
                                fallback: "Daily Login"
                            )
                        )
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                    } else {
                        GameHeader(progress: progress)
                            .padding(.top, 18)
                    }

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
                        .padding(.top, isCompactPresentation ? 12 : 50)
                        .padding(.trailing, isCompactPresentation ? 12 : 18)
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
                .frame(maxHeight: isCompactPresentation ? 430 : .infinity)
            }
        }
    }

    private var loginIDs: [String] {
        configuration.logins.map(\.id)
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: isCompactPresentation ? 74 : 92),
                spacing: isCompactPresentation ? 8 : 10
            )
        ]
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
            LazyVStack(spacing: isCompactPresentation ? 8 : 12) {
                loginSection(login)
            }
            .padding(.horizontal, isCompactPresentation ? 10 : 14)
            .padding(.bottom, isCompactPresentation ? 14 : 110)
        }
    }

    private func loginSection(_ login: DailyLoginCampaign) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localizedTitle(login))
                    .font(
                        .system(
                            size: isCompactPresentation ? 17 : 20,
                            weight: .heavy
                        )
                    )
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
        .padding(isCompactPresentation ? 10 : 12)
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
        let isClaimed = isToday && !progress.canClaimDailyLogin(for: login)

        return VStack(spacing: 7) {
            RemoteImage(name: reward.imageName)
                .frame(
                    width: isCompactPresentation ? 30 : 38,
                    height: isCompactPresentation ? 30 : 38
                )
                .saturation(isClaimed ? 0 : 1)
                .opacity(isClaimed ? 0.45 : 1)

            Text(localizedTitle(reward))
                .font(
                    .system(
                        size: isCompactPresentation ? 10 : 11,
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
                color: isClaimed ? .black.opacity(0.48) : .black
            )
            .strikethrough(isClaimed, color: .black.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .frame(height: isCompactPresentation ? 92 : 112)
        .padding(isCompactPresentation ? 6 : 8)
        .background(
            isClaimed
                ? .gray.opacity(0.76)
                : .white.opacity(isToday ? 0.96 : 0.82)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    canClaim ? .white.opacity(0.95) : .black.opacity(0.16),
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
