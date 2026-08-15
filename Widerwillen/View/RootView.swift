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
    @State private var internetConnectionStore = InternetConnectionStore()
    @State private var selectedTab: AppTab = .home
    @State private var activeMode: MenuMode?
    @State private var hasFinishedLaunchLoading = false
    @State private var hasStartedGame = false
    @State private var isFooterHiddenForActiveMode = false

    var body: some View {
        ZStack {
            if !internetConnectionStore.isConnected {
                OfflineView(
                    connectionName: internetConnectionStore.connectionName
                )
            } else if hasFinishedLaunchLoading {
                currentView
            } else {
                LaunchView(remoteContentStore: remoteContentStore)
            }

            if internetConnectionStore.isConnected
                && hasFinishedLaunchLoading && remoteContentStore.isRefreshing
                && !remoteContentStore.hasPendingUpdate
            {
                remoteContentProgressView
                    .padding(.horizontal, 28)
            }

            if internetConnectionStore.isConnected
                && hasFinishedLaunchLoading
                && remoteContentStore.hasPendingUpdate
            {
                remoteUpdatePrompt
                    .padding(.horizontal, 28)
            }

            if internetConnectionStore.isConnected
                && hasFinishedLaunchLoading && hasStartedGame
                && !remoteContentStore.hasPendingUpdate
            {
                TutorialCoachView(
                    progress: progress,
                    trigger: currentTutorialTrigger
                )
            }
        }
        .statusBarHidden(true)
        .onAppear {
            progress.refreshIdleRewards()
            musicPlayer.setEnabled(isMusicEnabled)
        }
        .task {
            guard internetConnectionStore.isConnected else { return }

            await remoteContentStore.loadLaunchContent()
            await MainActor.run {
                hasFinishedLaunchLoading = true
            }
            await remoteContentStore.checkForAvailableUpdate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && internetConnectionStore.isConnected {
                progress.refreshIdleRewards()
                Task {
                    await remoteContentStore.checkForAvailableUpdate()
                }
            }
        }
        .onChange(of: isMusicEnabled) { _, newValue in
            musicPlayer.setEnabled(newValue)
        }
        .onChange(of: selectedTab) { _, _ in
            Task {
                guard internetConnectionStore.isConnected else { return }
                await remoteContentStore.checkForAvailableUpdate()
            }
        }
        .onChange(of: activeMode) { _, _ in
            isFooterHiddenForActiveMode = false
            Task {
                guard internetConnectionStore.isConnected else { return }
                await remoteContentStore.checkForAvailableUpdate()
            }
        }
        .onChange(of: internetConnectionStore.isConnected) {
            _,
            isConnected in
            guard isConnected else { return }

            Task {
                if !hasFinishedLaunchLoading {
                    await remoteContentStore.loadLaunchContent()
                    await MainActor.run {
                        hasFinishedLaunchLoading = true
                    }
                }

                await remoteContentStore.checkForAvailableUpdate()
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

    private var remoteUpdatePrompt: some View {
        VStack(spacing: 14) {
            Text("Content Update")
                .font(.system(size: 18, weight: .heavy))

            if let version = remoteContentStore.pendingUpdateVersion {
                Text(
                    "Version \(version) • \(remoteContentStore.pendingUpdateSizeText)"
                )
                .font(.system(size: 12, weight: .bold))
                .opacity(0.78)
            }

            if remoteContentStore.isRefreshing {
                if let progress = remoteContentStore.progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                }

                Text(remoteContentStore.progressDetailText)
                    .font(.system(size: 11, weight: .bold))
                    .opacity(0.78)
            } else {
                HStack(spacing: 12) {
                    Button {
                        remoteContentStore.skipPendingUpdate()
                    } label: {
                        Text("Not now")
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        Task {
                            await remoteContentStore.applyPendingUpdate()
                        }
                    } label: {
                        Text("Download")
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.system(size: 14, weight: .heavy))
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .tint(.white)
        .padding(18)
        .frame(maxWidth: 320)
        .background(.black.opacity(0.78))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.65), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)
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
            SettingsView(progress: progress)
        case .news:
            NewsView()
        case .gift:
            GiftView(progress: progress)
        case .warehouse:
            warehouseView(progress: progress)
        case .pass:
            PassListView(progress: progress)
        case .dailyLogin:
            DailyLoginView(progress: progress)
        }
    }

    private var tabShell: some View {
        ZStack(alignment: .bottom) {
            selectedTabView

            Footer(selectedTab: $selectedTab, progress: progress)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var currentTutorialTrigger: TutorialTrigger {
        if let activeMode {
            switch activeMode {
            case .battle:
                return .battle
            case .event:
                return .event
            case .skills:
                return .skills
            case .warehouse:
                return .warehouse
            case .pass:
                return .shop
            case .settings:
                return .settings
            case .news:
                return .news
            case .gift:
                return .gift
            case .dailyLogin:
                return .dailyLogin
            }
        }

        switch selectedTab {
        case .home:
            return .launch
        case .sprites:
            return .sprites
        case .summon:
            return .summon
        case .shop:
            return .shop
        case .trade:
            return .trade
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
                    ),
                    progress: progress
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func usesFooterShell(_ mode: MenuMode) -> Bool {
        switch mode {
        case .event, .skills, .settings, .news, .gift, .warehouse, .pass,
            .dailyLogin:
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
