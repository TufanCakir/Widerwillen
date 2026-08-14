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
    private let shopConfiguration: ShopConfiguration

    @State private var store = StoreKitStore()
    @State private var selectedCategory = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        passConfiguration: PassConfiguration =
            (try? PassConfiguration.load()) ?? PassConfiguration(passes: []),
        shopConfiguration: ShopConfiguration =
            (try? ShopConfiguration.load()) ?? ShopConfiguration(
                crystalPacks: []
            )
    ) {
        self.progress = progress
        self.passConfiguration = passConfiguration
        self.shopConfiguration = shopConfiguration
        _selectedCategory = State(
            initialValue: shopConfiguration.categories.first?.id
                ?? "passes"
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                GameHeader(progress: progress)

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

                categoryBar

                TabView(selection: $selectedCategory) {
                    ForEach(categories) { category in
                        shopPage(for: category)
                            .tag(category.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top, 18)
        }
        .task {
            await store.loadProducts(productIDs: productIDs)
            syncOwnedNonConsumables()
        }
    }

    private var statusMessage: String {
        message.isEmpty ? store.message : message
    }

    private var productIDs: [String] {
        passConfiguration.passes.compactMap(\.productID)
            + shopConfiguration.allProductIDs
    }

    private var categories: [ShopCategory] {
        if !shopConfiguration.categories.isEmpty {
            return shopConfiguration.categories
        }

        return [
            ShopCategory(
                id: "passes",
                title: "Pass",
                imageName: "icon_pixel_relic"
            ),
            ShopCategory(
                id: "crystals",
                title: "Crystals",
                imageName: "icon_pixel_crystal"
            ),
        ]
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        selectedCategory = category.id
                    } label: {
                        HStack(spacing: 7) {
                            RemoteImage(name: category.imageName)
                                .frame(width: 20, height: 20)

                            Text(category.title)
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(height: 34)
                        .background {
                            Capsule()
                                .fill(
                                    selectedCategory == category.id
                                        ? .white.opacity(0.24)
                                        : .black.opacity(0.28)
                                )
                        }
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        }
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func shopPage(for category: ShopCategory) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                passSection(for: category)
                crystalSection(for: category)
                characterPackSection(for: category)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    @ViewBuilder
    private func passSection(for category: ShopCategory) -> some View {
        let passes = passConfiguration.passes.filter {
            ($0.category ?? "passes") == category.id
        }

        if !passes.isEmpty {
            ForEach(passes) { pass in
                PassView(
                    progress: progress,
                    pass: pass,
                    store: store
                ) { pass in
                    await buyPass(pass)
                }
            }
        }
    }

    @ViewBuilder
    private func crystalSection(for category: ShopCategory) -> some View {
        let packs = shopConfiguration.crystalPacks.filter {
            $0.category == category.id
        }

        if !packs.isEmpty {
            sectionTitle(category.title)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                ForEach(packs) { pack in
                    crystalPackCard(pack)
                }
            }
        }
    }

    @ViewBuilder
    private func characterPackSection(for category: ShopCategory) -> some View {
        let packs = shopConfiguration.characterPacks.filter {
            $0.category == category.id
        }

        if !packs.isEmpty {
            sectionTitle(category.title)

            LazyVStack(spacing: 12) {
                ForEach(packs) { pack in
                    characterPackCard(pack)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
    }

    private func crystalPackCard(_ pack: CrystalPack) -> some View {
        let isOwned = isOwnedNonConsumable(
            productID: pack.productID,
            purchaseType: pack.purchaseType
        )

        return Button {
            Task {
                await buyCrystalPack(pack)
            }
        } label: {
            VStack(spacing: 10) {
                RemoteImage(name: pack.imageName)
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                Text(pack.title)
                    .font(.system(size: 14, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let subtitle = pack.subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(0.75)
                }

                AppResourceLabel(
                    imageName: "icon_pixel_crystal",
                    value: pack.totalCrystals,
                    iconSize: 18,
                    fontSize: 12
                )

                if pack.bonusCrystals > 0 {
                    Text("+\(pack.bonusCrystals) Bonus")
                        .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.yellow)
                }

                if let limitedText = limitedText(for: pack.limitedUntil) {
                    Text(limitedText)
                        .font(.system(size: 9, weight: .heavy))
                        .opacity(0.75)
                }

                Text(isOwned ? "Owned" : store.displayPrice(for: pack.productID))
                    .font(.system(size: 13, weight: .heavy))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.24))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isOwned)
    }

    private func characterPackCard(_ pack: CharacterPack) -> some View {
        let isOwned = isOwnedNonConsumable(
            productID: pack.productID,
            purchaseType: pack.purchaseType
        )

        return Button {
            Task {
                await buyCharacterPack(pack)
            }
        } label: {
            HStack(spacing: 14) {
                RemoteImage(name: pack.imageName)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(pack.title)
                        .font(.system(size: 16, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let subtitle = pack.subtitle {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(2)
                            .opacity(0.75)
                    }

                    HStack(spacing: 8) {
                        if pack.bonusCrystals > 0 {
                            AppResourceLabel(
                                imageName: "icon_pixel_crystal",
                                value: pack.bonusCrystals,
                                prefix: "+",
                                iconSize: 16,
                                fontSize: 10
                            )
                        }

                        ForEach(pack.rewards) { reward in
                            AppResourceLabel(
                                imageName: reward.resource.imageName,
                                value: reward.amount,
                                prefix: "+",
                                iconSize: 16,
                                fontSize: 10
                            )
                        }
                    }

                    if let limitedText = limitedText(for: pack.limitedUntil) {
                        Text(limitedText)
                            .font(.system(size: 9, weight: .heavy))
                            .opacity(0.75)
                    }
                }

                Spacer()

                Text(isOwned ? "Owned" : store.displayPrice(for: pack.productID))
                    .font(.system(size: 13, weight: .heavy))
                    .frame(minWidth: 70)
                    .frame(height: 34)
                    .background(.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(12)
            .background(.black.opacity(0.24))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isOwned)
    }

    private func buyPass(_ pass: BattlePassDefinition) async {
        guard let productID = pass.productID else { return }

        if await store.purchase(productID: productID) {
            progress.unlockPremiumPass(pass)
            showMessage("Premium Pass unlocked")
        }
    }

    private func buyCrystalPack(_ pack: CrystalPack) async {
        guard !isOwnedNonConsumable(
            productID: pack.productID,
            purchaseType: pack.purchaseType
        ) else { return }

        if await store.purchase(productID: pack.productID) {
            progress.addPurchasedCrystals(pack.totalCrystals)
            showMessage("+\(pack.totalCrystals) crystals")
        }
    }

    private func buyCharacterPack(_ pack: CharacterPack) async {
        guard !isOwnedNonConsumable(
            productID: pack.productID,
            purchaseType: pack.purchaseType
        ) else { return }

        if await store.purchase(productID: pack.productID) {
            progress.unlockPurchasedCharacterPack(pack)
            showMessage("\(pack.title) unlocked")
        }
    }

    private func isOwnedNonConsumable(
        productID: String,
        purchaseType: ShopPurchaseType
    ) -> Bool {
        purchaseType == .nonConsumable
            && (store.purchasedProductIDs.contains(productID)
                || progress.isPurchasedShopProduct(productID))
    }

    private func syncOwnedNonConsumables() {
        for pass in passConfiguration.passes
        where pass.purchaseType == .nonConsumable {
            guard let productID = pass.productID,
                store.purchasedProductIDs.contains(productID)
            else {
                continue
            }

            progress.unlockPremiumPass(pass)
        }

        for pack in shopConfiguration.characterPacks
        where pack.purchaseType == .nonConsumable
            && store.purchasedProductIDs.contains(pack.productID)
        {
            progress.unlockPurchasedCharacterPack(pack)
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

    private func limitedText(for limitedUntil: String?) -> String? {
        guard let limitedUntil,
            let endDate = Self.parseLimitedDate(limitedUntil)
        else {
            return nil
        }

        let now = Date()
        let formattedDate = Self.germanDateFormatter.string(from: endDate)
        let remainingSeconds = Int(endDate.timeIntervalSince(now))

        guard remainingSeconds > 0 else {
            return "Endet am \(formattedDate)"
        }

        let days = remainingSeconds / 86_400
        let hours = (remainingSeconds % 86_400) / 3_600
        let minutes = (remainingSeconds % 3_600) / 60

        if days > 0 {
            return "Noch \(days) Tage bis \(formattedDate)"
        } else if hours > 0 {
            return "Noch \(hours) Std. bis \(formattedDate)"
        } else {
            return "Noch \(max(minutes, 1)) Min. bis \(formattedDate)"
        }
    }

    private static func parseLimitedDate(_ value: String) -> Date? {
        germanDateParser.date(from: value)
            ?? isoDateParser.date(from: value)
    }

    private static let germanDateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = .current
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private static let germanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let isoDateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

#Preview {
    ShopView(progress: GameProgressStore())
}
