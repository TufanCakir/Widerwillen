//
//  MenuView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct MenuView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void
    let openMode: (MenuMode) -> Void
    let homeResetSignal: Int
    let openBackgroundSignal: Int

    private let dailyLoginConfiguration: DailyLoginConfiguration

    @State private var isModePickerPresented = false
    @State private var isDailyLoginPopupPresented = false
    @State private var didEvaluateDailyLoginPopup = false
    @State private var selectedMenuPage: MenuPage = .home

    @AppStorage("selectedMenuShortcutIndex")
    private var selectedShortcutIndex = 0

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        homeResetSignal: Int = 0,
        openBackgroundSignal: Int = 0,
        dailyLoginConfiguration: DailyLoginConfiguration =
            try! DailyLoginConfiguration.load(),
        openMode: @escaping (MenuMode) -> Void
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.homeResetSignal = homeResetSignal
        self.openBackgroundSignal = openBackgroundSignal
        self.dailyLoginConfiguration = dailyLoginConfiguration
        self.openMode = openMode
    }

    var body: some View {
        ZStack {
            menuPageContent

            if isDailyLoginPopupPresented {
                dailyLoginPopup
            }
        }
        .background {
            AppBackground()
        }
        .onAppear {
            normalizeShortcutIndexIfNeeded()
            showDailyLoginPopupIfNeeded()
        }
        .onChange(of: homeResetSignal) { _, _ in
            selectedMenuPage = .home
            isModePickerPresented = false
        }
        .onChange(of: openBackgroundSignal) { _, _ in
            selectedMenuPage = .backgrounds
            isModePickerPresented = false
        }
    }

    private var nimbiCarouselStage: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.24))
                    .frame(width: 168, height: 168)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.20), lineWidth: 1)
                    }

                Circle()
                    .stroke(.cyan.opacity(0.45), lineWidth: 2)
                    .frame(width: 124, height: 124)
                    .shadow(color: .cyan.opacity(0.35), radius: 10)

                RemoteImage(name: "icon_nimpi")
                    .frame(width: 104, height: 104)
                    .shadow(color: .black.opacity(0.9), radius: 8, y: 5)
            }
        }
    }

    private var shortcutPager: some View {
        VStack(spacing: 8) {
            ZStack {
                ForEach(Array(shortcuts.enumerated()), id: \.element.id) {
                    index,
                    shortcut in
                    if let placement = shortcutPlacement(for: index) {
                        shortcutPagerButton(shortcut, placement: placement) {
                            handleShortcutTap(at: index)
                        }
                        .zIndex(placement.zIndex)
                    }
                }
            }
            .frame(height: 132)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { value in
                        if value.translation.width < -24 {
                            selectShortcut(selectedShortcutIndex + 1)
                        } else if value.translation.width > 24 {
                            selectShortcut(selectedShortcutIndex - 1)
                        }
                    }
            )

        }
        .padding(.horizontal, 18)
    }

    private var safeShortcutIndex: Int {
        guard !shortcuts.isEmpty else { return 0 }
        return min(max(selectedShortcutIndex, 0), shortcuts.count - 1)
    }

    private func shortcutPlacement(for index: Int) -> MenuShortcutPlacement? {
        let count = shortcuts.count
        guard count > 0 else { return nil }

        let selected = safeShortcutIndex
        let previous = (selected - 1 + count) % count
        let next = (selected + 1) % count

        if index == selected {
            return .active
        }

        if index == previous {
            return .previous
        }

        if index == next {
            return .next
        }

        return nil
    }

    private func selectShortcut(_ index: Int) {
        let count = shortcuts.count
        guard count > 0 else { return }
        let wrappedIndex = (index + count) % count

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            selectedShortcutIndex = wrappedIndex
        }
        playSoundEffect("ui_select")
    }

    private func normalizeShortcutIndexIfNeeded() {
        guard !shortcuts.isEmpty else {
            selectedShortcutIndex = 0
            return
        }

        if selectedShortcutIndex < 0 || selectedShortcutIndex >= shortcuts.count
        {
            selectedShortcutIndex = safeShortcutIndex
        }
    }

    private func handleShortcutTap(at index: Int) {
        if index == safeShortcutIndex {
            openShortcut(shortcuts[index])
        } else {
            selectShortcut(index)
        }
    }

    private func openShortcut(_ shortcut: MenuShortcut) {
        playSoundEffect("ui_navigation")

        if let mode = shortcut.mode {
            openMode(mode)
            return
        }

        if let page = shortcut.page {
            selectedMenuPage = page
        }
    }

    private func shortcutPagerButton(
        _ shortcut: MenuShortcut,
        placement: MenuShortcutPlacement,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    menuButtonBackground

                    Circle()
                        .stroke(.blue.opacity(0.72), lineWidth: 1)
                        .frame(
                            width: placement.ringSize,
                            height: placement.ringSize
                        )

                    RemoteImage(name: shortcut.assetImage)
                        .frame(
                            width: placement.iconSize,
                            height: placement.iconSize
                        )
                }
                .shadow(color: .black.opacity(0.75), radius: 5, y: 3)

                Text(shortcut.title)
                    .widerwillenFont(size: 10, weight: .bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: 82)
                    .opacity(placement.titleOpacity)
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .scaleEffect(placement.scale)
        .offset(x: placement.xOffset, y: placement.yOffset)
        .opacity(placement.opacity)
        .allowsHitTesting(placement.isInteractive)
    }

    private var menuButtonBackground: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.38))

            if let imageName = progress.selectedMenuButtonLook.imageName {
                RemoteImage(name: imageName, contentMode: .fill)
                    .clipShape(Circle())
                    .opacity(0.88)
            }
        }
        .frame(width: 76, height: 76)
        .overlay {
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var shortcuts: [MenuShortcut] {
        [
            MenuShortcut(
                title: "Showcase",
                assetImage: "icon_nimpi",
                mode: .showcase
            ),

            MenuShortcut(
                title: "Settings",
                assetImage: "icon_pixel_settings",
                page: .settings
            ),

            MenuShortcut(
                title: "BG",
                assetImage: "widerwillen_logo",
                page: .backgrounds
            ),

            MenuShortcut(
                title: "Skills",
                assetImage: "icon_pixel_skill_book",
                page: .skills
            ),

            MenuShortcut(
                title: "News",
                assetImage: "icon_pixel_news",
                page: .news
            ),

            MenuShortcut(
                title: "Giftbox",
                assetImage: "icon_pixel_giftbox",
                page: .gift
            ),

            MenuShortcut(
                title: "Equipment",
                assetImage: "icon_pixel_sword",
                page: .equipment
            ),

            MenuShortcut(
                title: "Warehouse",
                assetImage: "icon_pixel_box",
                page: .warehouse
            ),

            MenuShortcut(
                title: "Pass",
                assetImage: "icon_pixel_pass",
                page: .pass
            ),

            MenuShortcut(
                title: "Daily",
                assetImage: "icon_pixel_calendar",
                page: .dailyLogin
            ),
        ]
    }

    private var claimableDailyLogins: [DailyLoginCampaign] {
        dailyLoginConfiguration.logins.filter {
            progress.canClaimDailyLogin(for: $0)
        }
    }

    private var modePickerOverlay: some View {
        ZStack {
            Button {
                playSoundEffect("ui_back")
                withAnimation(.snappy(duration: 0.2)) {
                    isModePickerPresented = false
                }
            } label: {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .zIndex(0)

            VStack(spacing: 22) {
                popupButton(
                    title: "Battle",
                    mode: .battle
                )
                popupButton(
                    title: "Events",
                    mode: .event
                )
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background {
                AppBackground()
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .zIndex(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dailyLoginPopup: some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()

            DailyLoginView(
                progress: progress,
                playSoundEffect: playSoundEffect,
                configuration: dailyLoginConfiguration,
                isCompactPresentation: true
            ) {
                withAnimation(.snappy(duration: 0.2)) {
                    isDailyLoginPopupPresented = false
                }
            }
            .frame(maxWidth: 360)
            .frame(maxHeight: 560)
            .background(.black.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 44)
            .shadow(color: .black.opacity(0.92), radius: 10, x: 0, y: 5)
        }
        .zIndex(20)
    }

    private func popupButton(
        title: String,
        mode: MenuMode
    ) -> some View {
        Button {
            playSoundEffect("ui_confirm")
            isModePickerPresented = false
            openMode(mode)
        } label: {
            HStack(spacing: 20) {

                Text(title)
                    .widerwillenFont(size: 24, weight: .bold)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3
                    )
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background {
                AppBackground()
            }
            .overlay {
                Capsule()
                    .stroke(.blue, lineWidth: 1)
            }
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func showDailyLoginPopupIfNeeded() {
        guard !didEvaluateDailyLoginPopup else { return }
        didEvaluateDailyLoginPopup = true

        guard !claimableDailyLogins.isEmpty else { return }

        withAnimation(.snappy(duration: 0.24)) {
            isDailyLoginPopupPresented = true
        }
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            GameHeader(
                progress: progress
            )

            Spacer(minLength: 18)

            VStack(spacing: 18) {
                nimbiCarouselStage

                Button {
                    playSoundEffect("ui_select")
                    isModePickerPresented = true
                } label: {
                    Text("Start")
                        .widerwillenFont(size: 26, weight: .bold)
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background {
                            MenuButtonBackground(
                                imageName: progress.selectedMenuButtonLook
                                    .imageName
                            )
                            .clipShape(Capsule())
                        }
                        .overlay {
                            Capsule()
                                .stroke(.blue, lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                shortcutPager
            }
            .frame(maxWidth: 420)

            Spacer(minLength: 14)
        }
        .overlay {
            if isModePickerPresented {
                modePickerOverlay
            }
        }
    }

    @ViewBuilder
    private var menuPageContent: some View {
        switch selectedMenuPage {

        case .home:
            homeView

        case .backgrounds:
            BackgroundView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .skills:
            SkillView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .settings:
            SettingsView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .news:
            NewsView(
                playSoundEffect: playSoundEffect
            )

        case .gift:
            GiftView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .equipment:
            EquipmentView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .warehouse:
            warehouseView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .pass:
            PassListView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )

        case .dailyLogin:
            DailyLoginView(
                progress: progress,
                playSoundEffect: playSoundEffect
            )
        }
    }
}

enum MenuMode {
    case battle
    case showcase
    case event
    case skills
    case settings
    case news
    case gift
    case equipment
    case warehouse
    case pass
    case dailyLogin
}

private enum MenuPage {
    case home
    case backgrounds
    case skills
    case settings
    case news
    case gift
    case equipment
    case warehouse
    case pass
    case dailyLogin
}

private struct MenuShortcut: Identifiable {
    let title: String
    let assetImage: String
    let mode: MenuMode?
    let page: MenuPage?

    var id: String {
        "\(title)-\(assetImage)"
    }

    init(
        title: String,
        assetImage: String,
        mode: MenuMode? = nil,
        page: MenuPage? = nil
    ) {
        self.title = title
        self.assetImage = assetImage
        self.mode = mode
        self.page = page
    }
}

private enum MenuShortcutPlacement {
    case previous
    case active
    case next

    var scale: CGFloat {
        switch self {
        case .active:
            1.0

        case .previous, .next:
            0.74
        }
    }

    var xOffset: CGFloat {
        switch self {
        case .previous:
            -96

        case .active:
            0

        case .next:
            96
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .active:
            0

        case .previous, .next:
            20
        }
    }

    var opacity: Double {
        switch self {
        case .active:
            1.0

        case .previous, .next:
            0.66
        }
    }

    var titleOpacity: Double {
        switch self {
        case .active:
            1.0

        case .previous, .next:
            0.0
        }
    }

    var ringSize: CGFloat {
        switch self {
        case .active:
            62

        case .previous, .next:
            54
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .active:
            34

        case .previous, .next:
            30
        }
    }

    var zIndex: Double {
        switch self {
        case .active:
            3

        case .previous, .next:
            1
        }
    }

    var isInteractive: Bool {
        true
    }
}

#Preview {
    MenuView(progress: GameProgressStore()) { _ in }
}
