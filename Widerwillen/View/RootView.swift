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
    @AppStorage("isSoundEffectsEnabled") private var isSoundEffectsEnabled =
        true
    @AppStorage("isTutorialEnabled") private var isTutorialEnabled = true
    @AppStorage("musicVolume") private var musicVolume = 0.8
    @AppStorage("soundEffectsVolume") private var soundEffectsVolume = 0.9

    @State private var progress = GameProgressStore()
    @State private var musicPlayer = MusicPlayer()
    @State private var remoteContentStore = RemoteContentStore()
    @State private var internetConnectionStore = InternetConnectionStore()
    @State private var selectedTab: AppTab = .home
    @State private var activeMode: MenuMode?
    @State private var hasFinishedLaunchLoading = false
    @State private var hasStartedGame = false
    @State private var isFooterHiddenForActiveMode = false
    @State private var homeResetSignal = 0
    @State private var openBackgroundSignal = 0
    @State private var deepLinkedEventID: String?

    private let deepLinkConfiguration =
        (try? DeepLinkConfiguration.load())
        ?? DeepLinkConfiguration(
            scheme: "widerwillen",
            universalLinkHost: "remotewiderwillen.tufancakir.com",
            links: []
        )

    var body: some View {
        ZStack {
            if !internetConnectionStore.isConnected {
                OfflineView(
                    connectionName: internetConnectionStore.connectionName
                )
            } else if hasFinishedLaunchLoading
                && !remoteContentStore.isRefreshing
                && !remoteContentStore.hasPendingUpdate
            {
                currentView
            } else {
                LaunchView(remoteContentStore: remoteContentStore)
            }

            if internetConnectionStore.isConnected
                && hasFinishedLaunchLoading
                && remoteContentStore.hasPendingUpdate
            {
                remoteUpdatePrompt
                    .padding(.horizontal, 28)
            }

            if internetConnectionStore.isConnected
                && hasFinishedLaunchLoading && isTutorialEnabled
                && !remoteContentStore.hasPendingUpdate
                && !remoteContentStore.isRefreshing
            {
                TutorialCoachView(
                    progress: progress,
                    trigger: currentTutorialTrigger
                )
            }
        }
        .statusBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: hasFinishedLaunchLoading)
        .animation(
            .easeInOut(duration: 0.2),
            value: remoteContentStore.isRefreshing
        )
        .animation(
            .easeInOut(duration: 0.2),
            value: remoteContentStore.hasPendingUpdate
        )
        .onAppear {
            progress.refreshIdleRewards()
            musicPlayer.setMusicVolume(musicVolume)
            musicPlayer.setEnabled(isMusicEnabled)
            musicPlayer.setSoundEffectsVolume(soundEffectsVolume)
            musicPlayer.setSoundEffectsEnabled(isSoundEffectsEnabled)
        }
        .task {
            guard internetConnectionStore.isConnected else { return }

            await remoteContentStore.loadLaunchContent()
            musicPlayer.resumeIfNeeded()
            await MainActor.run {
                hasFinishedLaunchLoading = true
            }
            await remoteContentStore.checkForAvailableUpdate()
            musicPlayer.resumeIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && internetConnectionStore.isConnected {
                progress.refreshIdleRewards()
                musicPlayer.resumeIfNeeded()
                Task {
                    await remoteContentStore.checkForAvailableUpdate()
                }
            }
        }
        .onChange(of: isMusicEnabled) { _, newValue in
            musicPlayer.setEnabled(newValue)
        }

        .onChange(of: musicVolume) { _, newValue in
            musicPlayer.setMusicVolume(newValue)
        }

        .onChange(of: isSoundEffectsEnabled) { _, newValue in
            musicPlayer.setSoundEffectsEnabled(newValue)
        }

        .onChange(of: soundEffectsVolume) { _, newValue in
            musicPlayer.setSoundEffectsVolume(newValue)
        }
        .onOpenURL { url in
            handleDeepLink(url)
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
                    musicPlayer.resumeIfNeeded()
                    await MainActor.run {
                        hasFinishedLaunchLoading = true
                    }
                }

                await remoteContentStore.checkForAvailableUpdate()
                musicPlayer.resumeIfNeeded()
            }
        }
    }

    private var remoteUpdatePrompt: some View {
        VStack(spacing: 14) {
            Text("Content Update")
                .widerwillenFont(size: 18, weight: .heavy)

            if let version = remoteContentStore.pendingUpdateVersion {
                Text(
                    "Version \(version) • \(remoteContentStore.pendingUpdateSizeText)"
                )
                .widerwillenFont(size: 12, weight: .bold)
                .opacity(0.78)
            }

            progressBar

            Text(remoteContentStore.progressDetailText)
                .widerwillenFont(size: 11, weight: .bold)
                .opacity(0.78)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .tint(.white)
        .padding(18)
        .frame(maxWidth: 320)
        .background(.black.opacity(0.78))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)
        .transition(.opacity)
    }

    @ViewBuilder
    private var progressBar: some View {
        if let progress = remoteContentStore.progress {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        } else {
            ProgressView(value: 0.16)
                .progressViewStyle(.linear)
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
            GameView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect,
                stopSoundEffects: musicPlayer.stopAllSoundEffects
            ) {
                activeMode = nil
            }
        case .showcase:
            ShowcaseView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            ) {
                activeMode = nil
            }
        case .event:
            EventView(
                progress: progress,
                initialEventID: deepLinkedEventID,
                playSoundEffect: musicPlayer.playSoundEffect
            ) { isBattleActive in
                isFooterHiddenForActiveMode = isBattleActive
            }
        case .skills:
            SkillView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .settings:
            SettingsView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .news:
            NewsView(playSoundEffect: musicPlayer.playSoundEffect)
        case .gift:
            GiftView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .equipment:
            EquipmentView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .warehouse:
            warehouseView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .pass:
            PassListView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .dailyLogin:
            DailyLoginView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        }
    }

    private var tabShell: some View {
        ZStack(alignment: .bottom) {
            selectedTabView

            Footer(
                selectedTab: $selectedTab,
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect,
                onTabTap: handleFooterTabTap
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var currentTutorialTrigger: TutorialTrigger {
        if let activeMode {
            switch activeMode {
            case .battle:
                return .battle
            case .showcase:
                return .launch
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
            case .equipment:
                return .warehouse
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
                    progress: progress,
                    playSoundEffect: musicPlayer.playSoundEffect,
                    onTabTap: handleFooterTabTap
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func usesFooterShell(_ mode: MenuMode) -> Bool {
        switch mode {
        case .event, .skills, .settings, .news, .gift, .equipment, .warehouse,
            .pass, .dailyLogin:
            true
        case .battle, .showcase:
            false
        }
    }

    @ViewBuilder
    private var selectedTabView: some View {
        switch selectedTab {
        case .home:
            MenuView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect,
                homeResetSignal: homeResetSignal,
                openBackgroundSignal: openBackgroundSignal
            ) { activeMode = $0 }
        case .sprites:
            SpriteListView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .summon:
            SummonView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .shop:
            ShopView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        case .trade:
            TradeView(
                progress: progress,
                playSoundEffect: musicPlayer.playSoundEffect
            )
        }
    }

    private func handleFooterTabTap(_ tab: AppTab) {
        if tab == .home {
            activeMode = nil
            homeResetSignal += 1
        }
    }

    private func handleDeepLink(_ url: URL) {
        let configuration =
            (try? DeepLinkConfiguration.load()) ?? deepLinkConfiguration
        guard let link = configuration.resolve(url) else { return }

        hasStartedGame = true
        isFooterHiddenForActiveMode = false

        switch link.destination {
        case .home:
            activeMode = nil
            selectedTab = .home
            homeResetSignal += 1
        case .battle:
            activeMode = .battle
        case .showcase:
            activeMode = .showcase
        case .event:
            deepLinkedEventID = link.value
            activeMode = .event
        case .skills:
            activeMode = .skills
        case .settings:
            activeMode = .settings
        case .news:
            activeMode = .news
        case .gift:
            activeMode = .gift
        case .equipment:
            activeMode = .equipment
        case .warehouse:
            activeMode = .warehouse
        case .pass:
            activeMode = .pass
        case .dailyLogin:
            activeMode = .dailyLogin
        case .backgrounds:
            activeMode = nil
            selectedTab = .home
            openBackgroundSignal += 1
        case .sprites:
            activeMode = nil
            selectedTab = .sprites
        case .summon:
            activeMode = nil
            selectedTab = .summon
        case .shop:
            activeMode = nil
            selectedTab = .shop
        case .trade:
            activeMode = nil
            selectedTab = .trade
        }
    }
}

#Preview {
    RootView()
}
