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

    private let configuration: EventConfiguration
    @AppStorage("appLanguage") private var appLanguageCode =
        AppLanguage.de.rawValue
    @State private var message = ""
    @State private var selectedEvent: GameEvent?
    @State private var selectedCategory = ""

    init(
        progress: GameProgressStore,
        configuration: EventConfiguration = try! EventConfiguration.load(),
        playSoundEffect: @escaping (String) -> Void = { _ in },
        onBattleStateChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
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
                    playSoundEffect: playSoundEffect,
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
        VStack(spacing: 10) {
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

    private func eventPage(for category: String) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(events(in: category)) { event in
                    eventBanner(event)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 120)
        }
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

    private func eventBanner(_ event: GameEvent) -> some View {
        let remainingRuns = progress.remainingRuns(for: event)
        let chipBalance = progress.eventCurrencies[
            event.currencyStorageID,
            default: 0
        ]

        return Button {
            playSoundEffect("event_start")
            selectedEvent = event
            message = ""
        } label: {
            ZStack {
                RemoteImage(
                    name: event.cardBackgroundImageName ?? "bg_white",
                    contentMode: .fill
                )
                .frame(maxWidth: .infinity)
                .frame(height: 112)
                .clipped()
                .opacity(0.92)

                LinearGradient(
                    colors: [
                        .black.opacity(0.12),
                        .black.opacity(0.64),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack(spacing: 12) {
                    RemoteImage(name: event.bannerImageName)
                        .frame(width: 58, height: 58)
                        .padding(8)
                        .background(.black.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 4,
                            x: 0,
                            y: 2
                        )

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(localizedTitle(event))
                                .font(.system(size: 17, weight: .heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )

                            Spacer(minLength: 8)

                            Text("\(remainingRuns)/\(event.dailyLimit)")
                                .font(.system(size: 12, weight: .heavy))
                                .padding(.horizontal, 8)
                                .frame(height: 24)
                                .background(.black.opacity(0.36))
                                .clipShape(Capsule())
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )
                        }

                        Text("\(localizedCurrencyName(event)): \(chipBalance)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )

                        HStack(spacing: 9) {
                            eventRewardLabel(
                                imageName: event.currencyImageName,
                                value: event.rewards.chipAmount
                            )
                            eventRewardLabel(
                                imageName: "icon_pixel_coin",
                                value: event.rewards.coins
                            )
                            eventRewardLabel(
                                imageName: "icon_pixel_crystal",
                                value: event.rewards.crystals
                            )
                            eventRewardLabel(
                                imageName: "icon_pixel_relic",
                                value: event.rewards.relics
                            )
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.65), radius: 3, x: 0, y: 2)
            .opacity(remainingRuns > 0 ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(remainingRuns == 0)
    }

    private func eventRewardLabel(imageName: String, value: Int) -> some View {
        AppResourceLabel(
            imageName: imageName,
            value: value,
            prefix: "+",
            iconSize: 17,
            fontSize: 10
        )
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
                companionAnimationIDs: progress.battleCompanionAnimationIDs,
                spriteAttackInterval: progress.spriteAttackInterval,
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
                onSpriteAttack: {
                    guard progress.hasCompanionSprites else {
                        return BattleAttackResult(damageDealt: 0)
                    }

                    let result = attackEvent(damage: progress.spriteDamage)
                    playSoundEffect(
                        result.coinsAwarded > 0
                            ? "event_win"
                            : "battle_sprite_attack"
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
            crystalsAwarded: didClear ? event.rewards.crystals : 0
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
                    .font(.system(size: 30, weight: .heavy))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                Text(
                    "\(localizer.text("event.damage", fallback: "Damage")): \(summary.damageDealt)"
                )
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
                    .stroke(.white.opacity(0.85), lineWidth: 2)
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
}

private struct EventVictorySummary: Identifiable {
    let id = UUID()
    let damageDealt: Int
    let rewards: EventRewards
}

#Preview {
    EventView(progress: GameProgressStore())
}
