//
//  ShopView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct ShopView: View {
    let progress: GameProgressStore

    private let passConfiguration: PassConfiguration

    @State private var store = StoreKitStore()
    @State private var selectedPass: BattlePassDefinition?
    @State private var message = ""

    init(
        progress: GameProgressStore,
        passConfiguration: PassConfiguration =
            (try? PassConfiguration.load()) ?? PassConfiguration(passes: [])
    ) {
        self.progress = progress
        self.passConfiguration = passConfiguration
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.82))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(passConfiguration.passes) { pass in
                            passShopCard(pass)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
                }
            }

            if let selectedPass {
                rewardsOverlay(for: selectedPass)
            }
        }
        .task {
            await store.loadProducts(
                productIDs: passConfiguration.passes.compactMap(\.productID)
            )
            syncOwnedPasses()
        }
    }

    private var statusMessage: String {
        message.isEmpty ? store.message : message
    }

    private func passShopCard(_ pass: BattlePassDefinition) -> some View {
        let isUnlocked = progress.isPremiumPassUnlocked(pass)
        let productID = pass.productID
        let isPurchased =
            productID.map { store.purchasedProductIDs.contains($0) } ?? false

        return HStack(spacing: 14) {
            RemoteImage(name: pass.imageName)
                .frame(width: 58, height: 58)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(pass.title)
                    .font(.system(size: 20, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(pass.season)
                    .font(.system(size: 12, weight: .bold))
                    .opacity(0.74)

                HStack(spacing: 8) {
                    Text("\(pass.rewards.count) rewards")
                    Text("\(progress.passPoints(for: pass)) \(pass.pointName)")
                }
                .font(.system(size: 11, weight: .bold))
                .opacity(0.78)
            }

            Spacer()

            VStack(spacing: 8) {
                Button {
                    selectedPass = pass
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 22, weight: .heavy))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await buyPass(pass)
                    }
                } label: {
                    Text(
                        isUnlocked || isPurchased
                            ? "Owned"
                            : productID.map(store.displayPrice) ?? "Free"
                    )
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(
                        isUnlocked || isPurchased ? .white : .black
                    )
                    .frame(minWidth: 74)
                    .frame(height: 34)
                    .background(
                        isUnlocked || isPurchased
                            ? .black.opacity(0.32) : .white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.82), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(isUnlocked || isPurchased || productID == nil)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(.black.opacity(0.26))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.58), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func rewardsOverlay(for pass: BattlePassDefinition) -> some View {
        ZStack {
            Button {
                selectedPass = nil
            } label: {
                Color.black.opacity(0.52)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pass.title)
                            .font(.system(size: 20, weight: .heavy))

                        Text(pass.season)
                            .font(.system(size: 12, weight: .bold))
                            .opacity(0.74)
                    }

                    Spacer()

                    Button {
                        selectedPass = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(pass.rewards) { reward in
                            rewardInfoRow(reward, in: pass)
                        }
                    }
                }
                .frame(maxHeight: 390)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(14)
            .frame(maxWidth: 340)
            .background(.black.opacity(0.84))
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

    private func rewardInfoRow(
        _ reward: BattlePassReward,
        in pass: BattlePassDefinition
    ) -> some View {
        HStack(spacing: 11) {
            RemoteImage(name: reward.imageName)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(reward.title)
                        .font(.system(size: 13, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if reward.premium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(reward.requiredPoints) \(pass.pointName)")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.7)

                    ForEach(reward.rewards) { amount in
                        AppResourceLabel(
                            imageName: amount.imageName
                                ?? amount.resource.imageName,
                            value: amount.amount,
                            prefix: "+",
                            iconSize: 15,
                            fontSize: 10
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(9)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func buyPass(_ pass: BattlePassDefinition) async {
        guard let productID = pass.productID else { return }

        if await store.purchase(productID: productID) {
            progress.unlockPremiumPass(pass)
            showMessage("Premium Pass unlocked")
        }
    }

    private func syncOwnedPasses() {
        for pass in passConfiguration.passes
        where pass.purchaseType == .nonConsumable {
            guard let productID = pass.productID,
                store.purchasedProductIDs.contains(productID)
            else {
                continue
            }

            progress.unlockPremiumPass(pass)
        }
    }

    private func showMessage(_ value: String) {
        message = value

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                message = ""
            }
        }
    }
}

#Preview {
    ShopView(progress: GameProgressStore())
}
