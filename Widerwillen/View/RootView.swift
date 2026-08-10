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
    @State private var selectedTab: AppTab = .home
    @State private var activeMode: MenuMode?
    @State private var hasStartedGame = false

    var body: some View {
        currentView
            .statusBarHidden(true)
            .onAppear {
                progress.refreshIdleRewards()
                musicPlayer.setEnabled(isMusicEnabled)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    progress.refreshIdleRewards()
                }
            }
            .onChange(of: isMusicEnabled) { _, newValue in
                musicPlayer.setEnabled(newValue)
            }
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
            EventView(progress: progress)
        case .settings:
            SettingsView()
        case .news:
            NewsView()
        case .gift:
            GiftView(progress: progress)
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

    private func usesFooterShell(_ mode: MenuMode) -> Bool {
        switch mode {
        case .event, .settings, .news, .gift, .dailyLogin:
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
            warehouseView(progress: progress)
        case .trade:
            TradeView(progress: progress)
        }
    }
}

#Preview {
    RootView()
}
