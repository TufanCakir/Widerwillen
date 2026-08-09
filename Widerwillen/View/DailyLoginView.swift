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

    @State private var message = ""

    init(
        progress: GameProgressStore,
        configuration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load()
    ) {
        self.progress = progress
        self.configuration = configuration
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.82))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(
                            configuration.rewards.sorted { $0.day < $1.day }
                        ) {
                            reward in
                            rewardCard(reward)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
                }
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 118), spacing: 14)]
    }

    private func rewardCard(_ reward: DailyLoginReward) -> some View {
        let currentReward = progress.currentDailyLoginReward(
            from: configuration.rewards
        )
        let isToday = currentReward?.day == reward.day
        let canClaim = isToday && progress.canClaimDailyLogin

        return VStack(spacing: 10) {
            Image(reward.imageName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 54, height: 54)

            Text(reward.title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)

            ResourceAmountRow(amounts: reward.rewards, prefix: "+")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 138)
        .padding(10)
        .background(.black.opacity(isToday ? 0.34 : 0.22))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    canClaim
                        ? .white.opacity(0.95)
                        : isToday
                            ? .white.opacity(0.62)
                            : .white.opacity(0.35),
                    lineWidth: canClaim ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        .opacity(isToday || progress.canClaimDailyLogin ? 1 : 0.72)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            if canClaim {
                claim(reward)
            }
        }
    }

    private func claim(_ reward: DailyLoginReward) {
        message =
            progress.claimDailyLoginReward(reward)
            ? "Daily reward claimed"
            : "Already claimed today"

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { message = "" }
        }
    }
}

#Preview {
    DailyLoginView(progress: GameProgressStore())
}
