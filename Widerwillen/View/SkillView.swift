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
            initialValue: configuration.trees.first?.category
                ?? configuration.skills.first?.category ?? ""
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            GameHeader(progress: progress)
                .padding(.top, 18)

            HStack {
                AppResourceLabel(
                    imageName: "icon_pixel_skill_book",
                    value: progress.skillBooks,
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { skillBackground }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var skillBackground: some View {
        ZStack {
            RemoteImage(
                name: selectedTreeBackgroundImageName,
                contentMode: .fill
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()

            Color.black
                .opacity(0.18)
                .ignoresSafeArea()
        }
    }

    private var selectedTreeBackgroundImageName: String {
        tree(for: selectedCategory)?.backgroundImageName ?? "bg_app"
    }

    private var categories: [String] {
        var values: [String] = []

        for tree in configuration.trees where !values.contains(tree.category) {
            values.append(tree.category)
        }

        for skill in configuration.skills where !values.contains(skill.category)
        {
            values.append(skill.category)
        }

        return values
    }

    private func skillPage(for category: String) -> some View {
        let requiredLevel = requiredAccountLevel(for: category)
        let isUnlocked = progress.accountLevel >= requiredLevel

        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                treeHeader(for: category, requiredLevel: requiredLevel)

                if !isUnlocked {
                    lockedPathCard(
                        category: category,
                        requiredLevel: requiredLevel
                    )
                }

                ForEach(configuration.skills.filter { $0.category == category })
                {
                    skill in
                    skillCard(skill)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
        .background {
            Color.black.opacity(0.16)
        }
    }

    private func treeHeader(
        for category: String,
        requiredLevel: Int
    ) -> some View {
        let tree = tree(for: category)

        return ZStack(alignment: .bottomLeading) {
            RemoteImage(
                name: tree?.backgroundImageName ?? "bg_app",
                contentMode: .fill
            )
            .frame(height: 92)
            .clipped()

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(tree?.title ?? "\(category) Path")
                    .font(.system(size: 22, weight: .heavy))

                Text("Unlocks at account LV \(requiredLevel)")
                    .font(.system(size: 12, weight: .bold))
                    .opacity(0.76)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.44), lineWidth: 1)
        }
    }

    private func skillCard(_ skill: SkillNode) -> some View {
        let level = progress.skillLevel(for: skill)
        let requiredLevel = max(
            skill.requiredAccountLevel ?? 1,
            requiredAccountLevel(for: skill.category)
        )
        let isUnlocked = progress.accountLevel >= requiredLevel
        let canUpgrade = isUnlocked && progress.canUpgradeSkill(skill)

        return HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                RemoteImage(name: skill.imageName)
                    .frame(width: 52, height: 52)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(.black.opacity(0.62))
                        .clipShape(Circle())
                        .offset(x: 5, y: -5)
                }
            }

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

                Text(
                    isUnlocked
                        ? "Lv \(level)/\(skill.maxLevel)"
                        : "Unlocks at LV \(requiredLevel)"
                )
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white.opacity(0.86))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }

            Spacer(minLength: 8)

            Button {
                upgrade(skill)
            } label: {
                VStack(spacing: 3) {
                    RemoteImage(name: "icon_pixel_skill_book")
                        .frame(width: 22, height: 22)

                    Text("\(skill.cost)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }
                .frame(width: 54, height: 54)
                .background(.black.opacity(canUpgrade ? 0.48 : 0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            .white.opacity(canUpgrade ? 0.72 : 0.24),
                            lineWidth: 1
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!canUpgrade)
        }
        .opacity(isUnlocked ? 1 : 0.48)
        .padding(14)
        .background(.black.opacity(0.26))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.48), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func lockedPathCard(category: String, requiredLevel: Int)
        -> some View
    {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20, weight: .heavy))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(category) Path")
                    .font(.system(size: 16, weight: .heavy))

                Text("Unlocks at account LV \(requiredLevel)")
                    .font(.system(size: 12, weight: .bold))
                    .opacity(0.78)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.42), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func requiredAccountLevel(for category: String) -> Int {
        if let tree = tree(for: category) {
            return tree.requiredAccountLevel
        }

        return configuration.skills
            .filter { $0.category == category }
            .map { $0.requiredAccountLevel ?? 1 }
            .min() ?? 1
    }

    private func tree(for category: String) -> SkillTreeDefinition? {
        configuration.trees.first { $0.category == category }
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
        case .activeSkillDuration:
            return "+\(percent)% active skill duration per level"
        case .activeSkillCooldown:
            return "-\(percent)% active skill cooldown per level"
        case .stageSkipChance:
            return "+\(percent)% stage skip chance per level"
        }
    }

    private func upgrade(_ skill: SkillNode) {
        message =
            progress.upgradeSkill(skill)
            ? "Skill upgraded"
            : "Need more skill books"

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run { message = "" }
        }
    }
}

#Preview {
    SkillView(progress: GameProgressStore())
}
