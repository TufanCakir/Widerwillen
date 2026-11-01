//
//  SummonView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct SummonView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let configuration: SummonConfiguration

    @State private var selectedCategory = ""
    @State private var ratesBanner: SummonBanner?
    @State private var pendingSummon: PendingSummon?
    @State private var resultScreenResults: [SummonResult] = []
    @State private var isShowingResultScreen = false
    @State private var message = ""
    @State private var contentDate = Date.now

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        configuration: SummonConfiguration = try! SummonConfiguration.load()
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
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
                if visibleBanners.isEmpty {
                    Text("No banners available").foregroundStyle(
                        .white.opacity(0.7)
                    )
                }

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
        .refreshContentDate($contentDate)
        .onChange(of: visibleBanners.map(\.id), initial: true) { _, ids in
            if !categories.contains(selectedCategory) {
                selectedCategory = categories.first ?? ""
            }
            if let ratesBanner, !ids.contains(ratesBanner.id) {
                self.ratesBanner = nil
            }
            if let pendingSummon, !ids.contains(pendingSummon.banner.id) {
                self.pendingSummon = nil
            }
        }
        .fullScreenCover(isPresented: $isShowingResultScreen) {
            SummonResultView(results: resultScreenResults) {
                isShowingResultScreen = false
            }
        }
    }

    private var visibleBanners: [SummonBanner] {
        configuration.banners.filter { $0.schedule.isVisible(at: contentDate) }
    }

    private var categories: [String] {
        var values: [String] = []

        for banner in visibleBanners
        where !values.contains(banner.category) {
            values.append(banner.category)
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

    private func bannerPage(for category: String) -> some View {
        TabView {
            ForEach(visibleBanners.filter { $0.category == category }) {
                banner in
                bannerCard(banner)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private func bannerCard(_ banner: SummonBanner) -> some View {
        VStack(spacing: 34) {
            HStack {
                AppResourceLabel(
                    imageName: banner.currencyImageName,
                    value: Double(currencyAmount(for: banner)),
                    iconSize: 24,
                    fontSize: 13
                )

                Spacer()

                Button {
                    playSoundEffect("ui_select")
                    ratesBanner = banner
                } label: {
                    Label("Banner contents", systemImage: "square.stack.3d.up")
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
                .clipped()
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            VStack(spacing: 8) {
                Text(banner.title)
                    .widerwillenFont(size: 26, weight: .heavy)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                AvailabilityCountdownView(
                    startDate: banner.startDate,
                    endDate: banner.endDate
                )
            }

            HStack(spacing: 10) {
                summonButton(
                    title: "Single",
                    cost: banner.singleCost,
                    imageName: banner.currencyImageName,
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
                ) {
                    pendingSummon = PendingSummon(
                        banner: banner,
                        count: banner.multiCount,
                        cost: banner.multiCost
                    )
                }
            }
            .disabled(
                !banner.schedule.isActive()
                    || progress.accountLevel < banner.requiredAccountLevel
                    || !SummonDistribution(entries: banner.entries).canDraw
            )
            .opacity(banner.schedule.isActive() ? 1 : 0.45)
        }
        .padding()
    }

    private func summonButton(
        title: String,
        cost: Int,
        imageName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            playSoundEffect("ui_select")
            action()
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .widerwillenFont(size: 14, weight: .heavy)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                RemoteImage(name: imageName)
                    .frame(width: 16, height: 16)

                Text("\(cost)")
                    .widerwillenFont(size: 13, weight: .heavy)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )
            }
            .foregroundStyle(.white)
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
        SummonRatesOverlay(banner: banner) {
            playSoundEffect("ui_back")
            ratesBanner = nil
        }
        .id(banner.id)
    }

    private func confirmOverlay(_ pending: PendingSummon) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Summon?")
                    .widerwillenFont(size: 24, weight: .heavy)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                AppResourceLabel(
                    imageName: pending.banner.currencyImageName,
                    value: Double(pending.cost),
                    iconSize: 26,
                    fontSize: 16
                )

                HStack(spacing: 12) {
                    Button("Cancel") {
                        playSoundEffect("ui_back")
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
                .widerwillenFont(size: 14, weight: .heavy)
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
        let didSummon: Bool

        if pending.count == 1 {
            didSummon = progress.summonSingle(from: pending.banner)
        } else {
            didSummon = progress.summonMulti(from: pending.banner)
        }

        pendingSummon = nil

        if didSummon {
            playSoundEffect("ui_confirm")
            resultScreenResults = progress.lastSummonResults
            isShowingResultScreen = true
            message = ""
            return
        }

        playSoundEffect("ui_tap")
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
        case .character, .sprite, .item:
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
