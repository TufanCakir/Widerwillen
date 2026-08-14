//
//  EventView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct EventView: View {
    let progress: GameProgressStore
    let onBattleStateChange: (Bool) -> Void

    private let configuration: EventConfiguration
    @State private var message = ""
    @State private var selectedEvent: GameEvent?
    @State private var selectedCategory = ""

    init(
        progress: GameProgressStore,
        configuration: EventConfiguration = try! EventConfiguration.load(),
        onBattleStateChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.progress = progress
        self.onBattleStateChange = onBattleStateChange
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.events.first?.category ?? ""
        )
    }

    var body: some View {
        Group {
            if let selectedEvent {
                EventBattleView(
                    progress: progress,
                    event: selectedEvent,
                    onExit: {
                        self.selectedEvent = nil
                    }
                )
            } else {
                eventList
            }
        }
        .onAppear {
            progress.refreshDailyEventLimits(for: configuration.events)
            onBattleStateChange(selectedEvent != nil)
        }
        .onChange(of: selectedEvent?.id) { _, eventID in
            onBattleStateChange(eventID != nil)
        }
        .onDisappear {
            onBattleStateChange(false)
        }
    }

    private var eventList: some View {
        VStack(spacing: 12) {
            categoryBar

            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )
            }

            TabView(selection: $selectedCategory) {
                ForEach(eventCategories, id: \.self) { category in
                    eventPage(for: category)
                        .tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.top, 18)
        .background {
            AppBackground()
        }
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(eventCategories, id: \.self) { category in
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

    private func eventPage(for category: String) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(events(in: category)) { event in
                    eventBanner(event)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func events(in category: String) -> [GameEvent] {
        configuration.events.filter { $0.category == category }
    }

    private func eventBanner(_ event: GameEvent) -> some View {
        let remainingRuns = progress.remainingRuns(for: event)
        let eventCurrency = progress.eventCurrencies[event.id, default: 0]

        return Button {
            selectedEvent = event
            message = ""
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(name: event.bannerImageName)
                        .frame(maxWidth: .infinity)
                        .frame(height: 132)
                        .clipped()

                    LinearGradient(
                        colors: [.blue.opacity(0.0), .blue.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(event.title)
                                .font(.system(size: 20, weight: .heavy))
                                .lineLimit(1)
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )

                            Spacer()

                            Text("\(remainingRuns)/\(event.dailyLimit)")
                                .font(.system(size: 13, weight: .heavy))
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )
                        }

                        HStack(spacing: 12) {
                            AppResourceLabel(
                                imageName: event.currencyImageName,
                                value: event.rewards.eventCurrency,
                                prefix: "+",
                                iconSize: 20,
                                fontSize: 12
                            )
                            AppResourceLabel(
                                imageName: "icon_pixel_coin",
                                value: event.rewards.coins,
                                prefix: "+",
                                iconSize: 20,
                                fontSize: 12
                            )
                            AppResourceLabel(
                                imageName: "icon_pixel_crystal",
                                value: event.rewards.crystals,
                                prefix: "+",
                                iconSize: 20,
                                fontSize: 12
                            )
                            AppResourceLabel(
                                imageName: "icon_pixel_relic",
                                value: event.rewards.relics,
                                prefix: "+",
                                iconSize: 20,
                                fontSize: 12
                            )
                        }

                        HStack {
                            Text("\(event.currencyName): \(eventCurrency)")
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )

                            Spacer()

                            Text("HP \(event.hp)")
                                .font(.system(size: 12, weight: .bold))
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )
                        }
                        .foregroundStyle(.white.opacity(0.78))
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .opacity(remainingRuns > 0 ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(remainingRuns == 0)
    }
}

private struct EventBattleView: View {
    let progress: GameProgressStore
    let event: GameEvent
    let onExit: () -> Void

    @State private var currentHP: Int
    @State private var message = ""
    @State private var damageDealt = 0
    @State private var victorySummary: EventVictorySummary?

    init(
        progress: GameProgressStore,
        event: GameEvent,
        onExit: @escaping () -> Void
    ) {
        self.progress = progress
        self.event = event
        self.onExit = onExit
        _currentHP = State(initialValue: progress.eventMaxHP(for: event))
    }

    var body: some View {
        ZStack {
            BattleSceneView(
                progress: progress,
                title: event.title,
                healthTitle: "Event HP",
                currentHP: currentHP,
                maxHP: eventMaxHP,
                lookIndex: eventLookIndex,
                heroAnimationID: progress.battleHeroAnimationID,
                companionAnimationIDs: progress.battleCompanionAnimationIDs,
                spriteAttackInterval: progress.spriteAttackInterval,
                onTapAttack: {
                    attackEvent(damage: progress.tapDamage)
                },
                onSpriteAttack: {
                    guard progress.hasCompanionSprites else {
                        return BattleAttackResult(damageDealt: 0)
                    }

                    return attackEvent(damage: progress.spriteDamage)
                }
            )

            if let victorySummary {
                victoryOverlay(victorySummary)
            }
        }
        .task(id: victorySummary?.id) {
            guard victorySummary != nil else { return }

            try? await Task.sleep(for: .seconds(2.4))
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
            message = "Daily limit reached"
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
            message = "Daily limit reached"
            currentHP = eventMaxHP
        }

        return BattleAttackResult(damageDealt: actualDamage)
    }

    private func victoryOverlay(_ summary: EventVictorySummary) -> some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Victory")
                    .font(.system(size: 34, weight: .heavy))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                Text("Damage: \(summary.damageDealt)")
                    .font(.system(size: 14, weight: .bold))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                HStack(spacing: 12) {
                    AppResourceLabel(
                        imageName: event.currencyImageName,
                        value: summary.rewards.eventCurrency,
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
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .background {
                RemoteImage(name: "bg_app", contentMode: .fill)
                    .opacity(0.9)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.85), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: 3)
            .padding(.horizontal, 28)
        }
        .contentShape(Rectangle())
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
