//
//  SkillView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct SkillView: View {
    let progress: GameProgressStore

    private let configuration: SkillConfiguration

    @State private var selectedCategory = ""
    @State private var message = ""

    init(
        progress: GameProgressStore,
        configuration: SkillConfiguration = try! SkillConfiguration.load()
    ) {
        self.progress = progress
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.skills.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 16) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                HStack {
                    AppResourceLabel(
                        imageName: "icon_pixel_relic",
                        value: progress.artifactShards,
                        iconSize: 24,
                        fontSize: 14
                    )

                    Spacer()
                }
                .padding(.horizontal, 20)

                CategoryBar(
                    categories: categories,
                    selectedCategory: $selectedCategory
                )

                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.84))
                        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                }

                TabView(selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        skillPage(for: category)
                            .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for skill in configuration.skills where !values.contains(skill.category) {
            values.append(skill.category)
        }

        return values
    }

    private func skillPage(for category: String) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(configuration.skills.filter { $0.category == category }) {
                    skill in
                    skillCard(skill)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func skillCard(_ skill: SkillNode) -> some View {
        let level = progress.skillLevel(for: skill)
        let canUpgrade = progress.canUpgradeSkill(skill)

        return HStack(spacing: 14) {
            RemoteImage(name: skill.imageName)
                .frame(width: 52, height: 52)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(skill.title)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                Text(effectTitle(for: skill))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                Text("Lv \(level)/\(skill.maxLevel)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.86))
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }

            Spacer(minLength: 8)

            Button {
                upgrade(skill)
            } label: {
                VStack(spacing: 3) {
                    RemoteImage(name: "icon_pixel_relic")
                        .frame(width: 22, height: 22)

                    Text("\(skill.cost)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                }
                .frame(width: 54, height: 54)
                .background(.black.opacity(canUpgrade ? 0.48 : 0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(canUpgrade ? 0.72 : 0.24), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!canUpgrade)
        }
        .padding(14)
        .background(.black.opacity(0.26))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.48), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func effectTitle(for skill: SkillNode) -> String {
        let percent = Int((skill.valuePerLevel * 100).rounded())

        switch skill.effect {
        case .damage:
            return "+\(percent)% all damage per level"
        case .tapDamage:
            return "+\(percent)% tap damage per level"
        case .spriteDamage:
            return "+\(percent)% sprite damage per level"
        case .attackSpeed:
            return "+\(percent)% sprite speed per level"
        case .coinDrop:
            return "+\(percent)% coins per level"
        case .dropChance:
            return "+\(percent)% drop chance per level"
        case .prestigeRelics:
            return "+\(percent)% prestige relics per level"
        }
    }

    private func upgrade(_ skill: SkillNode) {
        message = progress.upgradeSkill(skill) ? "Skill upgraded" : "Need more relics"

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { message = "" }
        }
    }
}

#Preview {
    SkillView(progress: GameProgressStore())
}
