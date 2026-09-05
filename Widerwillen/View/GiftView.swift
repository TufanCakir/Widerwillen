//
//  GiftView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct GiftView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let configuration: GiftConfiguration

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var selectedCategory = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        configuration: GiftConfiguration = try! GiftConfiguration.load()
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.gifts.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 10) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                if !categories.isEmpty {
                    categoryBar
                }

                if !message.isEmpty {
                    statusText(message)
                }

                Group {
                    if categories.isEmpty {
                        emptyState
                            .padding(.horizontal, 16)
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
                .frame(maxHeight: .infinity)

                claimAllButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 92)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for gift in availableGifts where !values.contains(gift.category) {
            values.append(gift.category)
        }

        return values
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private func localizedCategory(_ category: String) -> String {
        let key =
            availableGifts.first { $0.category == category }?.categoryKey
            ?? configuration.gifts.first { $0.category == category }?
            .categoryKey
        return localizer.text(key, fallback: category)
    }

    private func localizedTitle(_ gift: GiftReward) -> String {
        localizer.text(gift.titleKey, fallback: gift.title)
    }

    private var availableGifts: [GiftReward] {
        configuration.gifts.filter { progress.canClaimGift($0) }
    }

    private var claimAllButton: some View {
        let hasGifts = !availableGifts.isEmpty

        return Button {
            playSoundEffect("ui_confirm")
            claimAll()
        } label: {
            Text(localizer.text("gift.claim_all", fallback: "Claim All"))
                .widerwillenFont(size: 18, weight: .heavy)
                .foregroundStyle(hasGifts ? .black : .white.opacity(0.54))
                .shadow(
                    color: hasGifts
                        ? .white.opacity(0.28) : .black.opacity(0.9),
                    radius: 2,
                    x: 0,
                    y: 0
                )
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(hasGifts ? .white : .black.opacity(0.28))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            .blue.opacity(hasGifts ? 0.88 : 0.28),
                            lineWidth: 1
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.9), radius: 7, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!hasGifts)
    }

    private var categoryBar: some View {
        CategoryBar(
            categories: categories,
            selectedCategory: $selectedCategory,
            playSoundEffect: playSoundEffect,
            displayName: localizedCategory
        )
    }

    private func giftPage(for category: String) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                let gifts = availableGifts.filter { $0.category == category }

                if gifts.isEmpty {
                    emptyState
                }

                ForEach(gifts) { gift in
                    giftCard(gift)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func giftCard(_ gift: GiftReward) -> some View {
        HStack(spacing: 10) {
            RemoteImage(name: gift.imageName)
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 6) {
                Text(localizedTitle(gift))
                    .widerwillenFont(size: 15, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                ResourceAmountRow(
                    amounts: gift.rewards,
                    prefix: "+",
                    iconSize: 16,
                    fontSize: 10
                )

                if !gift.unlocks.isEmpty {
                    unlockPreviewRow(gift.unlocks)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func unlockPreviewRow(_ unlocks: [TradeUnlockReward]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(unlocks) { unlock in
                    HStack(spacing: 5) {
                        RemoteImage(name: unlock.imageName)
                            .frame(width: 16, height: 16)

                        Text(unlock.name)
                            .widerwillenFont(size: 9, weight: .heavy)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(height: 23)
                    .background(.black.opacity(0.34))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private func claimAll() {
        let claimedCount = progress.claimGifts(availableGifts)
        message =
            claimedCount > 0
            ? localizer.text(
                "gift.claimed_count",
                fallback: "\(claimedCount) gifts claimed"
            )
            .replacingOccurrences(of: "{count}", with: "\(claimedCount)")
            : localizer.text(
                "gift.none_available",
                fallback: "No gifts available"
            )
        syncSelectedCategory()
        clearMessageSoon()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            RemoteImage(name: "icon_pixel_box")
                .frame(width: 62, height: 62)
                .opacity(0.45)

            Text(localizer.text("gift.empty", fallback: "No gifts"))
                .widerwillenFont(size: 16, weight: .heavy)
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
            .widerwillenFont(size: 13, weight: .heavy)
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
