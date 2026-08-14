//
//  PassView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct PassView: View {
    let progress: GameProgressStore
    let pass: BattlePassDefinition
    let store: StoreKitStore
    let buyPass: (BattlePassDefinition) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RemoteImage(name: pass.imageName)
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pass.title)
                        .font(.system(size: 20, weight: .heavy))
                    Text(pass.season)
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.75)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(progress.passPoints(for: pass))")
                        .font(.system(size: 18, weight: .heavy))
                    Text(pass.pointName)
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.75)
                }
            }

            if !progress.isPremiumPassUnlocked(pass),
                let productID = pass.productID
            {
                Button {
                    Task {
                        await buyPass(pass)
                    }
                } label: {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text(
                            store.purchasedProductIDs.contains(productID)
                                ? "Premium Pass Unlocked"
                                : "Premium Pass \(store.displayPrice(for: productID))"
                        )
                    }
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(.black.opacity(0.34))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.65), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(store.purchasedProductIDs.contains(productID))
            }

            LazyVStack(spacing: 10) {
                ForEach(pass.rewards) { reward in
                    rewardRow(reward)
                }
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func rewardRow(_ reward: BattlePassReward) -> some View {
        let isClaimed = progress.isPassRewardClaimed(reward, in: pass)
        let canClaim = progress.canClaimPassReward(reward, in: pass)
        let isLocked = !progress.isPassRewardUnlocked(reward, in: pass)

        return HStack(spacing: 12) {
            RemoteImage(name: reward.imageName)
                .frame(width: 36, height: 36)
                .opacity(isLocked ? 0.45 : 1)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(reward.title)
                        .font(.system(size: 14, weight: .heavy))
                        .lineLimit(1)

                    if reward.premium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(reward.requiredPoints) \(pass.pointName)")
                        .font(.system(size: 10, weight: .bold))
                        .opacity(0.72)

                    ForEach(reward.rewards) { amount in
                        AppResourceLabel(
                            imageName: amount.resource.imageName,
                            value: amount.amount,
                            prefix: "+",
                            iconSize: 16,
                            fontSize: 10
                        )
                    }
                }
            }

            Spacer()

            Button {
                _ = progress.claimPassReward(reward, in: pass)
            } label: {
                Image(
                    systemName: isClaimed
                        ? "checkmark.seal.fill"
                        : canClaim ? "gift.fill" : "lock.fill"
                )
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(isClaimed ? .green : .white)
                .frame(width: 42, height: 42)
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!canClaim)
            .opacity(canClaim || isClaimed ? 1 : 0.45)
        }
        .padding(10)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
