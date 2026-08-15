//
//  SummonView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct SummonView: View {
    let progress: GameProgressStore

    private let configuration: SummonConfiguration

    @State private var selectedCategory = ""
    @State private var ratesBanner: SummonBanner?
    @State private var pendingSummon: PendingSummon?
    @State private var resultScreenResults: [SummonResult] = []
    @State private var isShowingResultScreen = false
    @State private var message = ""

    init(
        progress: GameProgressStore,
        configuration: SummonConfiguration = try! SummonConfiguration.load()
    ) {
        self.progress = progress
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.banners.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                GameHeader(progress: progress)

                categoryBar

                TabView(selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        bannerPage(for: category)
                            .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            if let ratesBanner {
                ratesOverlayView(ratesBanner)
            }

            if let pendingSummon {
                confirmOverlay(pendingSummon)
            }

            if !message.isEmpty {
                messageOverlay
            }
        }
        .fullScreenCover(isPresented: $isShowingResultScreen) {
            SummonResultView(results: resultScreenResults) {
                isShowingResultScreen = false
            }
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for banner in configuration.banners
        where !values.contains(banner.category) {
            values.append(banner.category)
        }

        return values
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background {
                                Capsule()
                                    .fill(
                                        selectedCategory == category
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
                                y: 2
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func bannerPage(for category: String) -> some View {
        TabView {
            ForEach(configuration.banners.filter { $0.category == category }) {
                banner in
                bannerCard(banner)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private func bannerCard(_ banner: SummonBanner) -> some View {
        let isUnlocked = progress.accountLevel >= banner.requiredAccountLevel

        return VStack(spacing: 34) {
            HStack {
                AppResourceLabel(
                    imageName: banner.currencyImageName,
                    value: currencyAmount(for: banner),
                    iconSize: 24,
                    fontSize: 13
                )

                Spacer()

                Button {
                    ratesBanner = banner
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                }
                .buttonStyle(.plain)
            }

            RemoteImage(name: banner.bannerImageName)
                .frame(maxWidth: .infinity)
                .frame(height: 118)
                .opacity(isUnlocked ? 1 : 0.42)
                .clipped()
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            VStack(spacing: 8) {
                Text(banner.title)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                if !isUnlocked {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .heavy))

                        Text(
                            "Unlocks at account LV \(banner.requiredAccountLevel)"
                        )
                        .font(.system(size: 12, weight: .heavy))
                    }
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                }
            }

            HStack(spacing: 10) {
                summonButton(
                    title: "Single",
                    cost: banner.singleCost,
                    imageName: banner.currencyImageName,
                    isUnlocked: isUnlocked
                ) {
                    pendingSummon = PendingSummon(
                        banner: banner,
                        count: 1,
                        cost: banner.singleCost
                    )
                }

                summonButton(
                    title: "Multi",
                    cost: banner.multiCost,
                    imageName: banner.currencyImageName,
                    isUnlocked: isUnlocked
                ) {
                    pendingSummon = PendingSummon(
                        banner: banner,
                        count: banner.multiCount,
                        cost: banner.multiCost
                    )
                }
            }
        }
        .padding()
    }

    private func summonButton(
        title: String,
        cost: Int,
        imageName: String,
        isUnlocked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard isUnlocked else { return }
            action()
        } label: {
            HStack(spacing: 6) {
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .heavy))
                }

                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                RemoteImage(name: imageName)
                    .frame(width: 16, height: 16)

                Text("\(cost)")
                    .font(.system(size: 13, weight: .heavy))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )
            }
            .foregroundStyle(.white)
            .opacity(isUnlocked ? 1 : 0.48)
            .frame(maxWidth: .infinity)
            .padding()
            .background {
                RemoteImage(name: "icon_pixel_menü", contentMode: .fill)
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func ratesOverlayView(_ banner: SummonBanner) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { ratesBanner = nil }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rates")
                        .font(.system(size: 22, weight: .heavy))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )

                    Spacer()

                    Button {
                        ratesBanner = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .heavy))
                    }
                    .buttonStyle(.plain)
                }

                ForEach(banner.entries) { entry in
                    HStack(spacing: 10) {
                        RemoteImage(name: entry.imageName)
                            .frame(width: 28, height: 28)

                        Text(entry.name)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                        Spacer()
                        Text(entry.rarity.title)
                            .foregroundStyle(entry.rarity.color)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                        Text("\(Int(entry.weight))%")
                            .frame(width: 42, alignment: .trailing)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                    }
                    .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(.black.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 26)
        }
    }

    private func confirmOverlay(_ pending: PendingSummon) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Summon?")
                    .font(.system(size: 24, weight: .heavy))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                AppResourceLabel(
                    imageName: pending.banner.currencyImageName,
                    value: pending.cost,
                    iconSize: 26,
                    fontSize: 16
                )

                HStack(spacing: 12) {
                    Button("Cancel") {
                        pendingSummon = nil
                    }
                    .buttonStyle(.bordered)

                    Button("Confirm") {
                        runSummon(pending)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .foregroundStyle(.white)
            .padding(22)
            .background(.black.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var messageOverlay: some View {
        VStack {
            Spacer()

            Text(message)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.black.opacity(0.78))
                .clipShape(Capsule())
                .padding(.bottom, 132)
        }
    }

    private func runSummon(_ pending: PendingSummon) {
        guard progress.accountLevel >= pending.banner.requiredAccountLevel
        else {
            pendingSummon = nil
            message = "Unlocks at LV \(pending.banner.requiredAccountLevel)"
            clearMessageLater()
            return
        }

        let didSummon: Bool

        if pending.count == 1 {
            didSummon = progress.summonSingle(from: pending.banner)
        } else {
            didSummon = progress.summonMulti(from: pending.banner)
        }

        pendingSummon = nil

        if didSummon {
            resultScreenResults = progress.lastSummonResults
            isShowingResultScreen = true
            message = ""
            return
        }

        message = "Not enough currency"

        clearMessageLater()
    }

    private func clearMessageLater() {
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            await MainActor.run {
                message = ""
            }
        }
    }

    private func currencyAmount(for banner: SummonBanner) -> Int {
        switch banner.kind {
        case .sprite, .item:
            progress.crystals
        case .relic:
            progress.artifactShards
        }
    }
}

private struct PendingSummon {
    let banner: SummonBanner
    let count: Int
    let cost: Int
}

#Preview {
    SummonView(progress: GameProgressStore())
}
