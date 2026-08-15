//
//  warehouseView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct warehouseView: View {
    let progress: GameProgressStore

    private let eventConfiguration: EventConfiguration

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var selectedCategory = WarehouseCategory.currencies.rawValue

    init(
        progress: GameProgressStore,
        eventConfiguration: EventConfiguration = try! EventConfiguration.load()
    ) {
        self.progress = progress
        self.eventConfiguration = eventConfiguration
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                CategoryBar(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    displayName: localizedCategory
                )

                TabView(selection: $selectedCategory) {
                    currenciesPage
                        .tag(WarehouseCategory.currencies.rawValue)

                    eventChipsPage
                        .tag(WarehouseCategory.eventChips.rawValue)

                    relicsPage
                        .tag(WarehouseCategory.relics.rawValue)

                    equipmentPage
                        .tag(WarehouseCategory.equipment.rawValue)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onAppear {
            progress.refreshIdleRewards()
        }
    }

    private var categories: [String] {
        WarehouseCategory.allCases.map(\.rawValue)
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private func localizedCategory(_ category: String) -> String {
        WarehouseCategory(rawValue: category)
            .map { localizer.text($0.titleKey, fallback: $0.fallbackTitle) }
            ?? category
    }

    private var currenciesPage: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                idleRewardCard

                currencyCard(
                    titleKey: "warehouse.currency.coins",
                    fallbackTitle: "Coins",
                    imageName: "icon_pixel_coin",
                    amount: progress.coins
                )
                currencyCard(
                    titleKey: "warehouse.currency.crystals",
                    fallbackTitle: "Crystals",
                    imageName: "icon_pixel_crystal",
                    amount: progress.crystals
                )
                currencyCard(
                    titleKey: "warehouse.currency.relics",
                    fallbackTitle: "Relics",
                    imageName: "icon_pixel_relic",
                    amount: progress.artifactShards
                )
                currencyCard(
                    titleKey: "warehouse.currency.skill_books",
                    fallbackTitle: "Skill Books",
                    imageName: "icon_pixel_skill_book",
                    amount: progress.skillBooks
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private var idleRewardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        localizer.text(
                            "warehouse.idle.title",
                            fallback: "Idle Rewards"
                        )
                    )
                    .font(.system(size: 18, weight: .heavy))

                    Text(
                        localizer.text(
                            "warehouse.idle.subtitle",
                            fallback: "Rewards collected while away"
                        )
                    )
                    .font(.system(size: 11, weight: .bold))
                    .opacity(0.72)
                }

                Spacer()

                RemoteImage(name: "icon_pixel_box")
                    .frame(width: 46, height: 46)
                    .opacity(progress.hasPendingRewards ? 1 : 0.42)
            }

            HStack(spacing: 12) {
                AppResourceLabel(
                    imageName: "icon_pixel_coin",
                    value: progress.pendingCoins,
                    prefix: "+",
                    iconSize: 24,
                    fontSize: 14
                )

                AppResourceLabel(
                    imageName: "icon_pixel_crystal",
                    value: progress.pendingCrystals,
                    prefix: "+",
                    iconSize: 24,
                    fontSize: 14
                )

                Spacer()
            }

            Button {
                progress.claimIdleRewards()
            } label: {
                Text(
                    localizer.text(
                        "warehouse.claim",
                        fallback: "Claim"
                    )
                )
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(
                    progress.hasPendingRewards ? .black : .white.opacity(0.52)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    progress.hasPendingRewards ? .white : .black.opacity(0.28)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.86), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(!progress.hasPendingRewards)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(.black.opacity(0.28))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var eventChipsPage: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(eventConfiguration.events) { event in
                    currencyCard(
                        title: localizedCurrencyName(event),
                        imageName: event.currencyImageName,
                        amount: progress.eventCurrencies[event.id, default: 0],
                        subtitle: localizedEventTitle(event)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private var relicsPage: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if progress.ownedArtifacts.isEmpty {
                    emptyState(
                        imageName: "icon_pixel_relic",
                        titleKey: "warehouse.empty.relics",
                        fallbackTitle: "No relics"
                    )
                } else {
                    ForEach(
                        Array(progress.ownedArtifacts.values)
                            .sorted { $0.name < $1.name }
                    ) { artifact in
                        inventoryCard(
                            title: artifact.name,
                            imageName: artifact.imageName,
                            subtitle: "Lv \(artifact.level)",
                            valueText: "+\(artifact.damageBonus)"
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private var equipmentPage: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if progress.ownedItems.isEmpty {
                    emptyState(
                        imageName: "icon_pixel_box",
                        titleKey: "warehouse.empty.equipment",
                        fallbackTitle: "No equipment"
                    )
                } else {
                    ForEach(
                        Array(progress.ownedItems.values)
                            .sorted { $0.name < $1.name }
                    ) { item in
                        inventoryCard(
                            title: item.name,
                            imageName: item.imageName,
                            subtitle: "Lv \(item.level)",
                            valueText: "+\(item.damageBonus)"
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func currencyCard(
        titleKey: String,
        fallbackTitle: String,
        imageName: String,
        amount: Int
    ) -> some View {
        currencyCard(
            title: localizer.text(titleKey, fallback: fallbackTitle),
            imageName: imageName,
            amount: amount,
            subtitle: nil
        )
    }

    private func currencyCard(
        title: String,
        imageName: String,
        amount: Int,
        subtitle: String?
    ) -> some View {
        HStack(spacing: 14) {
            RemoteImage(name: imageName)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .bold))
                        .opacity(0.66)
                }
            }

            Spacer()

            Text(amount.formatted())
                .font(.system(size: 19, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.52), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func inventoryCard(
        title: String,
        imageName: String,
        subtitle: String,
        valueText: String
    ) -> some View {
        HStack(spacing: 14) {
            RemoteImage(name: imageName)
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.system(size: 11, weight: .bold))
                    .opacity(0.68)
            }

            Spacer()

            Text(valueText)
                .font(.system(size: 15, weight: .heavy))
                .opacity(0.84)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.52), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func emptyState(
        imageName: String,
        titleKey: String,
        fallbackTitle: String
    ) -> some View {
        VStack(spacing: 12) {
            RemoteImage(name: imageName)
                .frame(width: 58, height: 58)
                .opacity(0.45)

            Text(localizer.text(titleKey, fallback: fallbackTitle))
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white.opacity(0.72))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }

    private func localizedEventTitle(_ event: GameEvent) -> String {
        localizer.text(event.titleKey, fallback: event.title)
    }

    private func localizedCurrencyName(_ event: GameEvent) -> String {
        localizer.text(event.currencyNameKey, fallback: event.currencyName)
    }
}

private enum WarehouseCategory: String, CaseIterable {
    case currencies
    case eventChips
    case relics
    case equipment

    var titleKey: String {
        switch self {
        case .currencies:
            "warehouse.category.currencies"
        case .eventChips:
            "warehouse.category.event_chips"
        case .relics:
            "warehouse.category.relics"
        case .equipment:
            "warehouse.category.equipment"
        }
    }

    var fallbackTitle: String {
        switch self {
        case .currencies:
            "Currencies"
        case .eventChips:
            "Event Chips"
        case .relics:
            "Relics"
        case .equipment:
            "Equipment"
        }
    }
}

#Preview {
    warehouseView(progress: GameProgressStore())
}
