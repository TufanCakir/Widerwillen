//
//  ShopView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct ShopView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let shopConfiguration: ShopConfiguration
    private let passConfiguration: PassConfiguration

    @State private var store = StoreKitStore()
    @State private var selectedCategory = "passes"
    @State private var selectedPass: BattlePassDefinition?
    @State private var message = ""

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        shopConfiguration: ShopConfiguration =
            (try? ShopConfiguration.load())
            ?? ShopConfiguration(crystalPacks: []),
        passConfiguration: PassConfiguration =
            (try? PassConfiguration.load()) ?? PassConfiguration(passes: [])
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.shopConfiguration = shopConfiguration
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

                if activeCategories.count > 1 {
                    CategoryBar(
                        categories: activeCategories.map(\.id),
                        selectedCategory: $selectedCategory,
                        playSoundEffect: playSoundEffect
                    ) { categoryID in
                        activeCategories.first { $0.id == categoryID }?.title
                            ?? categoryID
                    }
                }

                TabView(selection: $selectedCategory) {
                    ForEach(activeCategories) { category in
                        shopPage(for: category.id)
                            .tag(category.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            if let selectedPass {
                rewardsOverlay(for: selectedPass)
            }
        }
        .task {
            if !activeCategories.contains(where: { $0.id == selectedCategory })
            {
                selectedCategory = defaultCategoryID
            }
            await store.loadProducts(productIDs: allProductIDs)
            syncOwnedPasses()
            syncOwnedCharacterPacks()
        }
    }

    private var statusMessage: String {
        message.isEmpty ? store.message : message
    }

    private var activeCategories: [ShopCategory] {
        let categories = shopConfiguration.categories
        guard !categories.isEmpty else {
            return [
                ShopCategory(
                    id: "passes",
                    title: "Pass",
                    imageName: "icon_pixel_relic"
                )
            ]
        }

        return categories
    }

    private var defaultCategoryID: String {
        activeCategories.first?.id ?? "passes"
    }

    private var allProductIDs: [String] {
        passConfiguration.passes.compactMap(\.productID)
            + shopConfiguration.allProductIDs
    }

    private var filteredPasses: [BattlePassDefinition] {
        passConfiguration.passes.filter {
            ($0.category ?? "passes") == selectedCategory
        }
    }

    private var filteredCrystalPacks: [CrystalPack] {
        shopConfiguration.crystalPacks.filter {
            $0.category == selectedCategory
        }
    }

    private var filteredCharacterPacks: [CharacterPack] {
        shopConfiguration.characterPacks.filter {
            $0.category == selectedCategory
        }
    }

    private func passes(in categoryID: String) -> [BattlePassDefinition] {
        passConfiguration.passes.filter {
            ($0.category ?? "passes") == categoryID
        }
    }

    private func crystalPacks(in categoryID: String) -> [CrystalPack] {
        shopConfiguration.crystalPacks.filter { $0.category == categoryID }
    }

    private func characterPacks(in categoryID: String) -> [CharacterPack] {
        shopConfiguration.characterPacks.filter { $0.category == categoryID }
    }

    private func shopPage(for categoryID: String) -> some View {
        let passes = passes(in: categoryID)
        let crystalPacks = crystalPacks(in: categoryID)
        let characterPacks = characterPacks(in: categoryID)

        return ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(passes) { pass in
                    passShopCard(pass)
                }

                ForEach(crystalPacks) { pack in
                    crystalPackCard(pack)
                }

                ForEach(characterPacks) { pack in
                    characterPackCard(pack)
                }

                if passes.isEmpty
                    && crystalPacks.isEmpty
                    && characterPacks.isEmpty
                {
                    Text("No offers")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.78))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
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
                    playSoundEffect("ui_select")
                    selectedPass = pass
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 22, weight: .heavy))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    playSoundEffect("ui_confirm")
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

    private func crystalPackCard(_ pack: CrystalPack) -> some View {
        HStack(spacing: 14) {
            RemoteImage(name: pack.imageName)
                .frame(width: 54, height: 54)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(pack.title)
                    .font(.system(size: 18, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let subtitle = pack.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.74)
                }

                HStack(spacing: 8) {
                    AppResourceLabel(
                        imageName: pack.imageName,
                        value: pack.totalCrystals,
                        prefix: "+",
                        iconSize: 18,
                        fontSize: 12
                    )

                    if pack.bonusCrystals > 0 {
                        Text("+\(pack.bonusCrystals) Bonus")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.yellow)
                    }
                }

                limitedText(pack.limitedUntil)
            }

            Spacer()

            buyButton(title: store.displayPrice(for: pack.productID)) {
                Task {
                    await buyCrystalPack(pack)
                }
            }
        }
        .shopCardStyle()
    }

    private func characterPackCard(_ pack: CharacterPack) -> some View {
        let isOwned =
            progress.isPurchasedShopProduct(pack.productID)
            || store.purchasedProductIDs.contains(pack.productID)

        return HStack(spacing: 14) {
            RemoteImage(name: pack.imageName)
                .frame(width: 54, height: 54)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(pack.title)
                    .font(.system(size: 18, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let subtitle = pack.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.74)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if pack.bonusCrystals > 0 {
                        AppResourceLabel(
                            imageName: "icon_pixel_crystal",
                            value: pack.bonusCrystals,
                            prefix: "+",
                            iconSize: 18,
                            fontSize: 12
                        )
                    }

                    ResourceAmountRow(
                        amounts: pack.rewards,
                        prefix: "+",
                        color: .white
                    )
                }

                limitedText(pack.limitedUntil)
            }

            Spacer()

            buyButton(
                title: isOwned
                    ? "Owned" : store.displayPrice(for: pack.productID),
                isDisabled: isOwned
            ) {
                Task {
                    await buyCharacterPack(pack)
                }
            }
        }
        .shopCardStyle()
    }

    @ViewBuilder
    private func limitedText(_ value: String?) -> some View {
        if let value, !value.isEmpty {
            Text("Bis \(value)")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(.yellow)
        }
    }

    private func buyButton(
        title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            playSoundEffect("ui_confirm")
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(isDisabled ? .white : .black)
                .frame(minWidth: 74)
                .frame(height: 34)
                .background(isDisabled ? .black.opacity(0.32) : .white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.82), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func rewardsOverlay(for pass: BattlePassDefinition) -> some View {
        ZStack {
            Button {
                playSoundEffect("ui_back")
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
                        playSoundEffect("ui_back")
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

    private func buyCrystalPack(_ pack: CrystalPack) async {
        if await store.purchase(productID: pack.productID) {
            progress.addPurchasedCrystals(pack.totalCrystals)
            showMessage("+\(pack.totalCrystals) crystals")
        }
    }

    private func buyCharacterPack(_ pack: CharacterPack) async {
        if await store.purchase(productID: pack.productID) {
            progress.unlockPurchasedCharacterPack(pack)
            showMessage("Pack unlocked")
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

    private func syncOwnedCharacterPacks() {
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
}

#Preview {
    ShopView(progress: GameProgressStore())
}

extension View {
    fileprivate func shopCardStyle() -> some View {
        self
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
}
