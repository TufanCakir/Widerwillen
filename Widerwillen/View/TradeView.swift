//
//  TradeView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct TradeView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let configuration: TradeConfiguration

    @State private var selectedCategory = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        configuration: TradeConfiguration = try! TradeConfiguration.load()
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.offers.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                GameHeader(progress: progress)

                categoryBar

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

                TabView(selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        offerPage(for: category)
                            .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top, 18)
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for offer in configuration.offers where !values.contains(offer.category)
        {
            values.append(offer.category)
        }

        return values
    }

    private var categoryBar: some View {
        CategoryBar(
            categories: categories,
            selectedCategory: $selectedCategory,
            playSoundEffect: playSoundEffect
        )
    }

    private func offerPage(for category: String) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(configuration.offers.filter { $0.category == category })
                { offer in
                    offerCard(offer)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func offerCard(_ offer: TradeOffer) -> some View {
        let canBuy = progress.canApplyTradeOffer(offer)
        let boughtCount = progress.tradeOfferPurchaseCounts[
            offer.id,
            default: 0
        ]

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                RemoteImage(name: offer.imageName)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text(offer.title)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )

                    HStack(spacing: 8) {
                        resourceRow(offer.costs, prefix: "-")
                        RemoteImage(name: "icon_pixel_trade")
                            .frame(width: 24, height: 24)
                        resourceRow(offer.rewards, prefix: "+")
                    }

                    if !offer.unlocks.isEmpty {
                        unlockRow(offer.unlocks)
                    }

                    if let limit = offer.limit {
                        Text("Limit \(boughtCount)/\(limit)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.72))
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                    }
                }

                Spacer()
            }

            Button {
                playSoundEffect("ui_confirm")
                apply(offer)
            } label: {
                RemoteImage(
                    name: canBuy ? "icon_pixel_box" : "icon_pixel_trade"
                )
                .frame(width: 48, height: 48)
                .opacity(canBuy ? 1 : 0.45)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!canBuy)
        }
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func resourceRow(
        _ amounts: [TradeResourceAmount],
        prefix: String
    ) -> some View {
        HStack(spacing: 6) {
            ForEach(amounts) { amount in
                AppResourceLabel(
                    imageName: amount.imageName ?? amount.resource.imageName,
                    value: amount.amount,
                    prefix: prefix,
                    iconSize: 20,
                    fontSize: 12
                )
            }
        }
    }

    private func unlockRow(_ unlocks: [TradeUnlockReward]) -> some View {
        HStack(spacing: 6) {
            ForEach(unlocks) { unlock in
                HStack(spacing: 5) {
                    RemoteImage(name: unlock.imageName)
                        .frame(width: 20, height: 20)

                    Text(unlock.name)
                        .font(.system(size: 11, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(.white.opacity(0.84))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }
        }
    }

    private func apply(_ offer: TradeOffer) {
        let didApply = progress.applyTradeOffer(offer)
        message = didApply ? "Trade complete" : "Not enough resources"

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                message = ""
            }
        }
    }
}

#Preview {
    TradeView(progress: GameProgressStore())
}
