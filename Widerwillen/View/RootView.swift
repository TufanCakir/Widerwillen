//
//  RootView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("isMusicEnabled") private var isMusicEnabled = true

    @State private var progress = GameProgressStore()
    @State private var musicPlayer = MusicPlayer()
    @State private var remoteContentStore = RemoteContentStore()
    @State private var selectedTab: AppTab = .home
    @State private var activeMode: MenuMode?
    @State private var hasStartedGame = false
    @State private var isFooterHiddenForActiveMode = false

    var body: some View {
        ZStack {
            currentView

            if remoteContentStore.isRefreshing {
                remoteContentProgressView
                    .padding(.horizontal, 28)
            }
        }
            .statusBarHidden(true)
            .onAppear {
                progress.refreshIdleRewards()
                musicPlayer.setEnabled(isMusicEnabled)
            }
            .task {
                await remoteContentStore.refreshIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    progress.refreshIdleRewards()
                    Task {
                        await remoteContentStore.refreshIfNeeded()
                    }
                }
            }
            .onChange(of: isMusicEnabled) { _, newValue in
                musicPlayer.setEnabled(newValue)
            }
            .onChange(of: selectedTab) { _, _ in
                Task {
                    await remoteContentStore.refreshIfNeeded()
                }
            }
            .onChange(of: activeMode) { _, _ in
                isFooterHiddenForActiveMode = false
                Task {
                    await remoteContentStore.refreshIfNeeded()
                }
            }
    }

    private var remoteContentProgressView: some View {
        VStack(spacing: 6) {
            if let progress = remoteContentStore.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
            }
        }
        .tint(.white)
        .frame(minWidth: 180)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var currentView: some View {
        if !hasStartedGame {
            StartView(hasStartedGame: $hasStartedGame)
        } else if let activeMode {
            if usesFooterShell(activeMode) {
                modeShell(activeMode)
            } else {
                modeView(activeMode)
            }
        } else {
            tabShell
        }
    }

    @ViewBuilder
    private func modeView(_ mode: MenuMode) -> some View {
        switch mode {
        case .battle:
            GameView(progress: progress) {
                activeMode = nil
            }
        case .event:
            EventView(progress: progress) { isBattleActive in
                isFooterHiddenForActiveMode = isBattleActive
            }
        case .skills:
            SkillView(progress: progress)
        case .settings:
            SettingsView()
        case .news:
            NewsView()
        case .gift:
            GiftView(progress: progress)
        case .warehouse:
            warehouseView(progress: progress)
        case .dailyLogin:
            DailyLoginView(progress: progress)
        }
    }

    private var tabShell: some View {
        ZStack(alignment: .bottom) {
            selectedTabView

            Footer(selectedTab: $selectedTab)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func modeShell(_ mode: MenuMode) -> some View {
        ZStack(alignment: .bottom) {
            modeView(mode)

            if !isFooterHiddenForActiveMode {
                Footer(
                    selectedTab: Binding(
                        get: { selectedTab },
                        set: { newTab in
                            selectedTab = newTab
                            activeMode = nil
                        }
                    )
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func usesFooterShell(_ mode: MenuMode) -> Bool {
        switch mode {
        case .event, .skills, .settings, .news, .gift, .warehouse, .dailyLogin:
            true
        case .battle:
            false
        }
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .home:
            MenuView(progress: progress) { activeMode = $0 }
        case .sprites:
            SpriteListView(progress: progress)
        case .summon:
            SummonView(progress: progress)
        case .shop:
            ShopView(progress: progress)
        case .trade:
            TradeView(progress: progress)
        }
    }
}

#Preview {
    RootView()
}
