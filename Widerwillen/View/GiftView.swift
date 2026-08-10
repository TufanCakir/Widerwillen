//
//  GiftView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct GiftView: View {
    let progress: GameProgressStore

    private let configuration: GiftConfiguration

    @State private var selectedCategory = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        configuration: GiftConfiguration = try! GiftConfiguration.load()
    ) {
        self.progress = progress
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.gifts.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                if !categories.isEmpty {
                    categoryBar
                }

                if !message.isEmpty {
                    statusText(message)
                }

                if categories.isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                    Spacer()
                } else {
                    TabView(selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            giftPage(for: category)
                                .tag(category)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }

            claimAllButton
                .padding(.horizontal, 24)
                .padding(.bottom, 96)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottom
                )
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for gift in availableGifts where !values.contains(gift.category) {
            values.append(gift.category)
        }

        return values
    }

    private var availableGifts: [GiftReward] {
        configuration.gifts.filter { progress.canClaimGift($0) }
    }

    private var claimAllButton: some View {
        let hasGifts = !availableGifts.isEmpty

        return Button {
            claimAll()
        } label: {
            Text("Claim All")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.black.opacity(hasGifts ? 0.54 : 0.28))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            .white.opacity(hasGifts ? 0.72 : 0.28),
                            lineWidth: 1
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!hasGifts)
    }

    private var categoryBar: some View {
        CategoryBar(categories: categories, selectedCategory: $selectedCategory)
    }

    private func giftPage(for category: String) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                let gifts = availableGifts.filter { $0.category == category }

                if gifts.isEmpty {
                    emptyState
                }

                ForEach(gifts) { gift in
                    giftCard(gift)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func giftCard(_ gift: GiftReward) -> some View {
        HStack(spacing: 14) {
            Image(gift.imageName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 8) {
                Text(gift.title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                ResourceAmountRow(amounts: gift.rewards, prefix: "+")
            }

            Spacer()
        }
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func claimAll() {
        let claimedCount = progress.claimGifts(availableGifts)
        message =
            claimedCount > 0
            ? "\(claimedCount) gifts claimed"
            : "No gifts available"
        syncSelectedCategory()
        clearMessageSoon()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image("icon_pixel_box")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 62, height: 62)
                .opacity(0.45)

            Text("No gifts")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white.opacity(0.72))
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }

    private func syncSelectedCategory() {
        guard !categories.contains(selectedCategory) else { return }
        selectedCategory = categories.first ?? ""
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy))
            .foregroundStyle(.white.opacity(0.82))
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func clearMessageSoon() {
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { message = "" }
        }
    }
}

#Preview {
    GiftView(progress: GameProgressStore())
}
