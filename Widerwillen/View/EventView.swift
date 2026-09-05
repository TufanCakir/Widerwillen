//
//  EventView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct EventView: View {

    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void
    let onBattleStateChange: (Bool) -> Void
    let initialEventID: String?

    private let configuration: EventConfiguration
    private let eventShopConfiguration: EventShopConfiguration

    @AppStorage("appLanguage")
    private var appLanguageCode = AppLanguage.de.rawValue

    @State private var message = ""
    @State private var selectedEvent: GameEvent?
    @State private var selectedCategory = ""
    @State private var selectedPreviewEventID: String?
    @State private var rewardDetailEvent: GameEvent?
    @State private var isEventShopPresented = false

    init(
        progress: GameProgressStore,
        initialEventID: String? = nil,
        configuration: EventConfiguration = try! EventConfiguration.load(),
        eventShopConfiguration: EventShopConfiguration =
            try! EventShopConfiguration.load(),
        playSoundEffect: @escaping (String) -> Void = { _ in },
        onBattleStateChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.progress = progress
        self.initialEventID = initialEventID
        self.playSoundEffect = playSoundEffect
        self.onBattleStateChange = onBattleStateChange
        self.configuration = configuration
        self.eventShopConfiguration = eventShopConfiguration

        let initialEvent = initialEventID.flatMap { eventID in
            configuration.events.first { $0.id == eventID }
        }
        _selectedCategory = State(
            initialValue: initialEvent?.category
                ?? configuration.events.first?.category ?? ""
        )
        _selectedPreviewEventID = State(
            initialValue: initialEvent?.id
        )
    }

    var body: some View {
        Group {
            if let selectedEvent {
                EventBattleView(
                    progress: progress,
                    event: selectedEvent,
                    playSoundEffect: playSoundEffect,
                    onExit: {
                        self.selectedEvent = nil
                    }
                )
            } else if isEventShopPresented {
                EventShopView(
                    progress: progress,
                    events: configuration.events,
                    eventShopConfiguration: eventShopConfiguration,
                    playSoundEffect: playSoundEffect
                ) {
                    isEventShopPresented = false
                }
            } else {
                eventList
            }
        }
        .onAppear {
            progress.refreshDailyEventLimits(for: configuration.events)
            selectDefaultPreviewEventIfNeeded(for: selectedCategory)
            onBattleStateChange(selectedEvent != nil)
        }
        .onChange(of: selectedCategory) { _, category in
            selectDefaultPreviewEventIfNeeded(for: category)
        }
        .onChange(of: initialEventID) { _, eventID in
            selectInitialEvent(eventID)
        }
        .onChange(of: selectedEvent?.id) { _, eventID in
            onBattleStateChange(eventID != nil)
        }
        .onDisappear {
            onBattleStateChange(false)
        }
    }

    private var eventList: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 10) {
                categoryBar
                eventShopEntryButton

                if !message.isEmpty {
                    Text(message)
                        .widerwillenFont(size: 13, weight: .heavy)
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }

                eventPage(for: selectedCategory)
                    .animation(.snappy(duration: 0.22), value: selectedCategory)
            }
            .padding(.top, 18)

            if let rewardDetailEvent {
                eventDetailPopup(for: rewardDetailEvent)
            }
        }
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private var eventCategories: [String] {
        var categories: [String] = []

        for event in configuration.events
        where !categories.contains(event.category) {
            categories.append(event.category)
        }

        return categories
    }

    private var categoryBar: some View {
        CategoryBar(
            categories: eventCategories,
            selectedCategory: $selectedCategory,
            playSoundEffect: playSoundEffect,
            displayName: localizedCategory
        )
    }

    private var eventShopEntryButton: some View {
        Button {
            playSoundEffect("ui_select")
            isEventShopPresented = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 14, weight: .heavy))

                Text("Event Shops")
                    .widerwillenFont(size: 13, weight: .heavy)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(.black.opacity(0.24))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private func eventPage(for category: String) -> some View {
        VStack(spacing: 0) {
            if let event = selectedPreviewEvent(for: category) {

                // FESTER HERO-BEREICH OBEN
                eventHero(event)
                    .frame(height: 230)
                    .padding(.horizontal, 16)
                    .zIndex(2)

                // Klarer Abstand zwischen Hero und Wheel
                Spacer()
                    .frame(height: 20)

                eventWheel(for: category)
                    .frame(height: 238)
                    .zIndex(1)

            } else {
                Spacer()

                Text("No Events")
                    .widerwillenFont(size: 18, weight: .heavy)
                    .foregroundStyle(.white.opacity(0.78))

                Spacer()
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 100)
    }

    private func selectedPreviewEvent(for category: String) -> GameEvent? {
        let categoryEvents = events(in: category)

        if let selectedPreviewEventID,
            let event = categoryEvents.first(where: {
                $0.id == selectedPreviewEventID
            })
        {
            return event
        }

        return categoryEvents.first
    }

    private func selectDefaultPreviewEventIfNeeded(for category: String) {
        let categoryEvents = events(in: category)

        guard !categoryEvents.isEmpty else {
            selectedPreviewEventID = nil
            return
        }

        if let selectedPreviewEventID,
            categoryEvents.contains(where: { $0.id == selectedPreviewEventID })
        {
            return
        }

        selectedPreviewEventID = categoryEvents.first?.id
    }

    private func selectInitialEvent(_ eventID: String?) {
        guard let eventID,
            let event = configuration.events.first(where: { $0.id == eventID })
        else {
            return
        }

        selectedCategory = event.category
        selectedPreviewEventID = event.id
    }

    private func eventHero(_ event: GameEvent) -> some View {
        ZStack(alignment: .topTrailing) {

            // Nur Anzeige – KEIN Button
            ZStack {
                RemoteImage(
                    name: event.cardBackgroundImageName ?? "bg_white",
                    contentMode: .fill
                )
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .clipped()
                .opacity(0.92)

                LinearGradient(
                    colors: [
                        .black.opacity(0.10),
                        .black.opacity(0.54)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RemoteImage(name: event.bannerImageName)
                    .frame(width: 126, height: 126)
                    .padding(18)
                    .background(.black.opacity(0.28))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.20), lineWidth: 1)
                    }
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 8,
                        y: 5
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue.opacity(0.9), lineWidth: 1)
            }
            .shadow(
                color: .black.opacity(0.68),
                radius: 5,
                y: 3
            )

            // Nur ? bleibt anklickbar
            Button {
                playSoundEffect("ui_select")
                rewardDetailEvent = event
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.56))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
    }

    private func eventWheel(for category: String) -> some View {
        let categoryEvents = events(in: category)
        let selectedIndex = selectedEventIndex(in: category)

        return VStack(spacing: 8) {
            wheelStepButton(systemName: "chevron.up") {
                selectRelativeEvent(-1, in: category)
            }
            .opacity(categoryEvents.count > 1 ? 1 : 0)
            .disabled(categoryEvents.count <= 1)

            ZStack {
                ForEach(Array(categoryEvents.enumerated()), id: \.element.id) {
                    index,
                    event in
                    if let placement = EventWheelPlacement(
                        index: index,
                        selectedIndex: selectedIndex
                    ) {
                        eventWheelButton(event, placement: placement) {
                            handleEventWheelTap(event, in: category)
                        }
                        .offset(y: placement.yOffset)
                        .scaleEffect(placement.scale)
                        .opacity(placement.opacity)
                        .zIndex(placement.zIndex)
                    }
                }
            }
            .frame(height: 158)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { value in
                        guard abs(value.translation.height)
                            > abs(value.translation.width)
                        else { return }

                        if value.translation.height < 0 {
                            selectRelativeEvent(1, in: category)
                        } else {
                            selectRelativeEvent(-1, in: category)
                        }
                    }
            )

            wheelStepButton(systemName: "chevron.down") {
                selectRelativeEvent(1, in: category)
            }
            .opacity(categoryEvents.count > 1 ? 1 : 0)
            .disabled(categoryEvents.count <= 1)
        }
        .padding(.horizontal, 16)
    }

    private func eventWheelButton(
        _ event: GameEvent,
        placement: EventWheelPlacement,
        action: @escaping () -> Void
    ) -> some View {
        let isSelected = placement == .active
        let remainingRuns = progress.remainingRuns(for: event)

        return Button(action: action) {
            HStack(spacing: 12) {
                RemoteImage(name: event.bannerImageName)
                    .frame(
                        width: isSelected ? 40 : 30,
                        height: isSelected ? 40 : 30
                    )
                    .padding(isSelected ? 6 : 4)
                    .background(.black.opacity(0.24))
                    .clipShape(Circle())

                Text(localizedTitle(event))
                    .widerwillenFont(
                        size: isSelected ? 16 : 13,
                        weight: .heavy
                    )
                    .foregroundStyle(
                        .white.opacity(isSelected ? 1.0 : 0.45)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Text("\(remainingRuns)/\(event.dailyLimit)")
                    .widerwillenFont(
                        size: isSelected ? 13 : 11,
                        weight: .heavy
                    )
                    .foregroundStyle(
                        remainingRuns > 0
                            ? .white.opacity(isSelected ? 0.9 : 0.45)
                            : .red.opacity(0.75)
                    )
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(.black.opacity(0.32))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? .white.opacity(0.16)
                            : .black.opacity(0.20)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        .blue.opacity(isSelected ? 1.0 : 0.35),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func wheelStepButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 42, height: 28)
                .background(.black.opacity(0.28))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(.blue.opacity(0.55), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func handleEventWheelTap(_ event: GameEvent, in category: String) {
        guard selectedPreviewEventID == event.id else {
            withAnimation(.snappy(duration: 0.18)) {
                selectedCategory = category
                selectedPreviewEventID = event.id
            }
            playSoundEffect("ui_select")
            return
        }

        guard progress.remainingRuns(for: event) > 0 else {
            playSoundEffect("ui_tap")
            message = "No runs left"
            return
        }

        playSoundEffect("event_start")
        selectedEvent = event
        message = ""
    }

    private func selectedEventIndex(in category: String) -> Int {
        let categoryEvents = events(in: category)

        guard let selectedPreviewEventID,
            let index = categoryEvents.firstIndex(where: {
                $0.id == selectedPreviewEventID
            })
        else {
            return 0
        }

        return index
    }

    private func selectRelativeEvent(_ offset: Int, in category: String) {
        let categoryEvents = events(in: category)
        guard !categoryEvents.isEmpty else { return }

        let currentIndex = selectedEventIndex(in: category)
        let nextIndex = (
            currentIndex + offset + categoryEvents.count
        ) % categoryEvents.count

        withAnimation(.snappy(duration: 0.18)) {
            selectedPreviewEventID = categoryEvents[nextIndex].id
        }
        playSoundEffect("ui_select")
    }

    private func eventDetailPopup(for event: GameEvent) -> some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()
                .onTapGesture {
                    playSoundEffect("ui_back")
                    rewardDetailEvent = nil
                }

            VStack(spacing: 14) {
                HStack {
                    Text(localizedTitle(event))
                        .widerwillenFont(size: 20, weight: .heavy)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Button {
                        playSoundEffect("ui_back")
                        rewardDetailEvent = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.black.opacity(0.44))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        rewardDetailRow(
                            imageName: event.currencyImageName,
                            title: localizedCurrencyName(event),
                            value: event.rewards.chipAmount
                        )

                        rewardDetailRow(
                            imageName: "icon_pixel_coin",
                            title: "Coins",
                            value: event.rewards.coins
                        )

                        rewardDetailRow(
                            imageName: "icon_pixel_crystal",
                            title: "Crystals",
                            value: event.rewards.crystals
                        )

                        rewardDetailRow(
                            imageName: "icon_pixel_relic",
                            title: "Relics",
                            value: event.rewards.relics
                        )

                        rewardDetailRow(
                            imageName: "icon_pixel_skill_book",
                            title: "Skill Books",
                            value: event.rewards.skillBooks
                        )

                        ForEach(event.unlocks) { unlock in
                            rewardDetailRow(
                                imageName: unlock.imageName,
                                title: unlock.name,
                                value: 1
                            )
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
            .padding(16)
            .frame(maxWidth: 360)
            .background {
                AppBackground()
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.9), radius: 10, y: 5)
            .padding(.horizontal, 20)
        }
        .zIndex(30)
    }
    
    private func rewardDetailRow(
        imageName: String,
        title: String,
        value: Int
    ) -> some View {
        HStack(spacing: 12) {
            RemoteImage(name: imageName)
                .frame(width: 34, height: 34)

            Text(title)
                .widerwillenFont(size: 13, weight: .heavy)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()

            Text("+\(value)")
                .widerwillenFont(size: 13, weight: .heavy)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func rewardDetailRow(
        systemImage: String,
        title: String,
        value: Int
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .heavy))
                .frame(width: 34, height: 34)
                .background(.black.opacity(0.32))
                .clipShape(Circle())

            Text(title)
                .widerwillenFont(size: 13, weight: .heavy)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()

            Text("+\(value)")
                .widerwillenFont(size: 13, weight: .heavy)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func events(in category: String) -> [GameEvent] {
        configuration.events.filter { $0.category == category }
    }

    private func localizedCategory(_ category: String) -> String {
        let key = configuration.events.first { $0.category == category }?
            .categoryKey
        return localizer.text(key, fallback: category)
    }

    private func localizedTitle(_ event: GameEvent) -> String {
        localizer.text(event.titleKey, fallback: event.title)
    }

    private func localizedCurrencyName(_ event: GameEvent) -> String {
        localizer.text(event.currencyNameKey, fallback: event.currencyName)
    }

}

private enum EventWheelPlacement {
    case previous
    case active
    case next

    init?(index: Int, selectedIndex: Int) {
        switch index - selectedIndex {
        case -1:
            self = .previous
        case 0:
            self = .active
        case 1:
            self = .next
        default:
            return nil
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .previous:
            return -54
        case .active:
            return 0
        case .next:
            return 54
        }
    }

    var scale: CGFloat {
        switch self {
        case .active:
            return 1
        case .previous, .next:
            return 0.92
        }
    }

    var opacity: Double {
        switch self {
        case .active:
            return 1
        case .previous, .next:
            return 0.52
        }
    }

    var zIndex: Double {
        switch self {
        case .active:
            return 3
        case .previous, .next:
            return 1
        }
    }
}

private struct EventShopView: View {

    let progress: GameProgressStore
    let events: [GameEvent]
    let eventShopConfiguration: EventShopConfiguration
    let playSoundEffect: (String) -> Void
    let onExit: () -> Void

    @AppStorage("appLanguage") private var appLanguageCode =
        AppLanguage.de.rawValue
    @State private var selectedShopEvent: GameEvent?
    @State private var message = ""

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                header

                if !message.isEmpty {
                    Text(message)
                        .widerwillenFont(size: 13, weight: .heavy)
                        .foregroundStyle(.white.opacity(0.82))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(shopEvents) { event in
                            shopButton(for: event)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
                }
            }
            .padding(.top, 18)

            if let selectedShopEvent {
                shopWindow(for: selectedShopEvent)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                playSoundEffect("ui_back")
                onExit()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Text("Event Shops")
                .widerwillenFont(size: 22, weight: .heavy)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private var shopEvents: [GameEvent] {
        events.filter { event in
            guard let shop = eventShopConfiguration.shop(for: event.id) else {
                return false
            }

            return !shop.offers.isEmpty
        }
    }

    private func shopButton(for event: GameEvent) -> some View {
        let shop = eventShopConfiguration.shop(for: event.id)!
        let chipBalance = progress.eventCurrencies[shop.currencyID, default: 0]
        let offerCount = shop.offers.count

        return Button {
            playSoundEffect("ui_select")
            selectedShopEvent = event
        } label: {
            HStack(spacing: 14) {
                RemoteImage(name: shop.currencyImageName)
                    .frame(width: 48, height: 48)
                    .padding(8)
                    .background(.black.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 6) {
                    Text(shop.title)
                        .widerwillenFont(size: 17, weight: .heavy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(offerCount) Offers")
                        .widerwillenFont(size: 11, weight: .bold)
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Text(chipBalance.formatted())
                    .widerwillenFont(size: 16, weight: .heavy)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(14)
            .background(.black.opacity(0.24))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func shopWindow(for event: GameEvent) -> some View {
        let shop = eventShopConfiguration.shop(for: event.id)
        let offers = shop?.offers ?? []

        return ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedShopEvent = nil
                }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    RemoteImage(name: shop?.currencyImageName ?? event.currencyImageName)
                        .frame(width: 28, height: 28)

                    Text(shop?.title ?? "\(localizedCurrencyName(event)) Shop")
                        .widerwillenFont(size: 18, weight: .heavy)

                    Spacer()

                    Button {
                        playSoundEffect("ui_back")
                        selectedShopEvent = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(offers) { offer in
                            offerCard(offer)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: 360)
            .background(.black.opacity(0.82))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.9), radius: 10, x: 0, y: 6)
            .padding(.horizontal, 20)
        }
    }

    private func offerCard(_ offer: TradeOffer) -> some View {
        let canBuy = progress.canApplyTradeOffer(offer)
        let boughtCount = progress.tradeOfferPurchaseCounts[
            offer.id,
            default: 0
        ]

        return HStack(spacing: 10) {
            RemoteImage(name: offer.imageName)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 5) {
                Text(offer.title)
                    .widerwillenFont(size: 13, weight: .heavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 7) {
                    resourceRow(offer.costs, prefix: "-")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .heavy))
                    resourceRow(offer.rewards, prefix: "+")
                    unlockRow(offer.unlocks)
                }

                if let limit = offer.limit {
                    Text("Limit \(boughtCount)/\(limit)")
                        .widerwillenFont(size: 9, weight: .heavy)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }

            Spacer()

            Button {
                playSoundEffect("ui_confirm")
                apply(offer)
            } label: {
                Text(canBuy ? "Buy" : "Need")
                    .widerwillenFont(size: 10, weight: .heavy)
                    .foregroundStyle(canBuy ? .black : .white.opacity(0.54))
                    .frame(width: 54, height: 28)
                    .background(canBuy ? .white : .black.opacity(0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!canBuy)
        }
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(10)
        .background(.white.opacity(canBuy ? 0.1 : 0.04))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(canBuy ? 0.55 : 0.22), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func resourceRow(
        _ amounts: [TradeResourceAmount],
        prefix: String
    ) -> some View {
        HStack(spacing: 5) {
            ForEach(amounts) { amount in
                AppResourceLabel(
                    imageName: amount.imageName ?? amount.resource.imageName,
                    value: amount.amount,
                    prefix: prefix,
                    iconSize: 16,
                    fontSize: 9
                )
            }
        }
    }

    private func unlockRow(_ unlocks: [TradeUnlockReward]) -> some View {
        HStack(spacing: 5) {
            ForEach(unlocks) { unlock in
                RemoteImage(name: unlock.imageName)
                    .frame(width: 16, height: 16)
            }
        }
    }

    private func apply(_ offer: TradeOffer) {
        let didApply = progress.applyTradeOffer(offer)
        message = didApply ? "Bought" : "Not enough chips"

        Task {
            try? await Task.sleep(for: .seconds(1.1))
            await MainActor.run {
                message = ""
            }
        }
    }

    private func localizedCurrencyName(_ event: GameEvent) -> String {
        localizer.text(event.currencyNameKey, fallback: event.currencyName)
    }
}

private struct EventBattleView: View {
    let progress: GameProgressStore
    let event: GameEvent
    let playSoundEffect: (String) -> Void
    let onExit: () -> Void

    @AppStorage("appLanguage") private var appLanguageCode =
        AppLanguage.de.rawValue
    @State private var currentHP: Int
    @State private var message = ""
    @State private var damageDealt = 0
    @State private var victorySummary: EventVictorySummary?

    init(
        progress: GameProgressStore,
        event: GameEvent,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        onExit: @escaping () -> Void
    ) {
        self.progress = progress
        self.event = event
        self.playSoundEffect = playSoundEffect
        self.onExit = onExit
        _currentHP = State(initialValue: progress.eventMaxHP(for: event))
    }

    var body: some View {
        ZStack {
            BattleSceneView(
                progress: progress,
                title: localizedTitle(event),
                healthTitle: localizer.text("event.hp", fallback: "Event HP"),
                currentHP: currentHP,
                maxHP: eventMaxHP,
                lookIndex: eventLookIndex,
                heroAnimationID: progress.battleHeroAnimationID,
                equippedWeaponImageName: progress.equippedWeaponImageName,
                activeSkills: progress.activeBattleSkills,
                backgroundImageName: event.battleBackgroundImageName,
                groundImageName: event.battleGroundImageName,
                onTapAttack: {
                    let result = attackEvent(damage: progress.tapDamage)
                    playSoundEffect(
                        result.coinsAwarded > 0 ? "event_win" : "battle_tap"
                    )
                    return result
                },
                onBattleCardAttack: { card in
                    let damage = max(
                        1,
                        Int(
                            (Double(progress.tapDamage) * card.damageMultiplier)
                                .rounded()
                        )
                    )
                    let result = attackEvent(damage: damage)
                    playSoundEffect(
                        result.coinsAwarded > 0 ? "event_win" : "battle_tap"
                    )
                    return result
                },
                onActiveSkillAttack: { skill in
                    playSoundEffect("battle_skill")
                    return attackEvent(damage: skill.damage)
                }
            )

            if let victorySummary {
                victoryOverlay(victorySummary)
            }
        }
        .task(id: victorySummary?.id) {
            guard victorySummary != nil else { return }

            try? await Task.sleep(
                for: .seconds(event.victory.dismissDelaySeconds)
            )
            await MainActor.run {
                onExit()
            }
        }
    }

    private var eventLookIndex: Int {
        abs(event.id.hashValue) % 16
    }

    private var eventMaxHP: Int {
        progress.eventMaxHP(for: event)
    }

    private func attackEvent(damage: Int) -> BattleAttackResult {
        guard victorySummary == nil else {
            return BattleAttackResult(damageDealt: 0)
        }

        guard progress.remainingRuns(for: event) > 0 else {
            currentHP = eventMaxHP
            message = localizer.text(
                "event.daily_limit_reached",
                fallback: "Daily limit reached"
            )
            return BattleAttackResult(damageDealt: 0)
        }

        let damageValue = max(damage, 1)
        let actualDamage = min(damageValue, currentHP)
        damageDealt += actualDamage
        currentHP = max(currentHP - damageValue, 0)

        guard currentHP == 0 else {
            return BattleAttackResult(damageDealt: actualDamage)
        }

        let didClear = progress.fightEvent(event)
        if didClear {
            victorySummary = EventVictorySummary(
                damageDealt: damageDealt,
                rewards: event.rewards
            )
        } else {
            message = localizer.text(
                "event.daily_limit_reached",
                fallback: "Daily limit reached"
            )
            currentHP = eventMaxHP
        }

        return BattleAttackResult(
            damageDealt: actualDamage,
            coinsAwarded: didClear ? event.rewards.coins : 0,
            crystalsAwarded: didClear ? event.rewards.crystals : 0,
            relicsAwarded: didClear ? event.rewards.relics : 0,
            skillBooksAwarded: didClear ? event.rewards.skillBooks : 0,
            eventChipsAwarded: didClear ? event.rewards.chipAmount : 0,
            eventChipImageName: event.currencyImageName
        )
    }

    private func victoryOverlay(_ summary: EventVictorySummary) -> some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                if let imageName = event.victory.imageName {
                    RemoteImage(name: imageName)
                        .frame(width: 58, height: 58)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }

                Text(localizedVictoryTitle)
                    .widerwillenPixelFont(size: 30, weight: .heavy)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                Text(
                    "\(localizer.text("event.damage", fallback: "Damage")): \(summary.damageDealt)"
                )
                .widerwillenFont(size: 14, weight: .bold)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )

                HStack(spacing: 12) {
                    AppResourceLabel(
                        imageName: event.currencyImageName,
                        value: summary.rewards.chipAmount,
                        prefix: "+",
                        iconSize: 24,
                        fontSize: 13
                    )

                    AppResourceLabel(
                        imageName: "icon_pixel_coin",
                        value: summary.rewards.coins,
                        prefix: "+",
                        iconSize: 24,
                        fontSize: 13
                    )

                    AppResourceLabel(
                        imageName: "icon_pixel_crystal",
                        value: summary.rewards.crystals,
                        prefix: "+",
                        iconSize: 24,
                        fontSize: 13
                    )

                    AppResourceLabel(
                        imageName: "icon_pixel_relic",
                        value: summary.rewards.relics,
                        prefix: "+",
                        iconSize: 24,
                        fontSize: 13
                    )

                    AppResourceLabel(
                        imageName: "icon_pixel_skill_book",
                        value: summary.rewards.skillBooks,
                        prefix: "+",
                        iconSize: 24,
                        fontSize: 13
                    )
                }

                if !event.unlocks.isEmpty {
                    unlockPreviewRow(event.unlocks, iconSize: 26)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .background {
                RemoteImage(
                    name: event.victory.backgroundImageName,
                    contentMode: .fill
                )
                .opacity(0.9)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.blue, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 3)
            .padding(.horizontal, 28)
        }
        .contentShape(Rectangle())
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private func localizedTitle(_ event: GameEvent) -> String {
        localizer.text(event.titleKey, fallback: event.title)
    }

    private var localizedVictoryTitle: String {
        localizer.text(event.victory.titleKey, fallback: event.victory.title)
    }

    private func unlockPreviewRow(
        _ unlocks: [TradeUnlockReward],
        iconSize: CGFloat
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(unlocks) { unlock in
                HStack(spacing: 6) {
                    RemoteImage(name: unlock.imageName)
                        .frame(width: iconSize, height: iconSize)

                    Text(unlock.name)
                        .widerwillenFont(
                            size: iconSize > 20 ? 13 : 10,
                            weight: .heavy
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 8)
                .frame(height: iconSize > 20 ? 34 : 24)
                .background(.black.opacity(0.34))
                .clipShape(Capsule())
            }
        }
    }
}

private struct EventVictorySummary: Identifiable {
    let id = UUID()
    let damageDealt: Int
    let rewards: EventRewards
}

#Preview {
    EventView(progress: GameProgressStore())
}
