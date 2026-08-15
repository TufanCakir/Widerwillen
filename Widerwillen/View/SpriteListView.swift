//
//  SpriteListView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct SpriteListView: View {
    let progress: GameProgressStore

    @State private var selectedCategory: SpriteCollectionCategory = .characters

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 14)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 12) {
                categoryBar

                TabView(selection: $selectedCategory) {
                    ForEach(SpriteCollectionCategory.allCases, id: \.self) {
                        category in
                        collectionPage(for: category)
                            .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top, 24)
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SpriteCollectionCategory.allCases, id: \.self) {
                    category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 7) {
                            RemoteImage(name: category.imageName)
                                .frame(width: 20, height: 20)

                            Text(category.title)
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
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
                            y: 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func collectionPage(for category: SpriteCollectionCategory)
        -> some View
    {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionTitle(category.title)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(items(for: category)) { item in
                        Button {
                            select(item)
                        } label: {
                            collectionCard(item)
                        }
                        .buttonStyle(.plain)
                        .disabled(!item.canSelect)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)
        }
    }

    private func items(for category: SpriteCollectionCategory)
        -> [CollectionItem]
    {
        switch category {
        case .characters:
            characterItems
        case .skins:
            skinItems
        case .companions:
            companionItems
        case .relics:
            relicItems
        case .items:
            itemItems
        }
    }

    private var characterItems: [CollectionItem] {
        progress.characterDefinitions.map { character in
            let owned = progress.ownedCharacterList.first {
                $0.characterID == character.id
            }
            let skin =
                character.skins.first { $0.id == character.defaultSkinID }
                ?? character.skins.first

            return CollectionItem(
                id: "character-\(character.id)",
                name: character.name,
                imageName: skin?.imageName ?? "icon_nimpi",
                rarity: character.rarity,
                levelTitle: owned == nil ? "Locked" : nil,
                stars: owned?.stars,
                isSelected: progress.isSelectedCharacter(character.id),
                canSelect: owned != nil,
                character: character,
                skin: nil
            )
        }
    }

    private var skinItems: [CollectionItem] {
        progress.characterDefinitions.flatMap { character in
            character.skins.map { skin in
                let isUnlocked =
                    progress.isSkinUnlocked(skin)
                    && progress.ownedCharacterList.contains {
                        $0.characterID == character.id
                    }

                return CollectionItem(
                    id: "skin-\(skin.id)",
                    name: skin.name,
                    imageName: skin.imageName,
                    rarity: character.rarity,
                    levelTitle: isUnlocked ? character.name : "Locked",
                    stars: nil,
                    isSelected: progress.isSelectedSkin(skin),
                    canSelect: isUnlocked,
                    character: character,
                    skin: skin
                )
            }
        }
    }

    private var companionItems: [CollectionItem] {
        progress.ownedSprites.values.map {
            CollectionItem(
                id: "sprite-\($0.spriteIndex)",
                name: $0.name,
                imageName: $0.imageName,
                rarity: $0.rarity,
                levelTitle: nil,
                stars: $0.stars,
                isSelected: false,
                canSelect: false,
                character: nil,
                skin: nil
            )
        }
        .sorted { sortedCollectionItem($0, before: $1) }
    }

    private var relicItems: [CollectionItem] {
        progress.ownedArtifacts.values.map {
            CollectionItem(
                id: "relic-\($0.artifactID)",
                name: $0.name,
                imageName: $0.imageName,
                rarity: $0.rarity,
                levelTitle: "Lv \($0.level)",
                stars: nil,
                isSelected: false,
                canSelect: false,
                character: nil,
                skin: nil
            )
        }
        .sorted { sortedCollectionItem($0, before: $1) }
    }

    private var itemItems: [CollectionItem] {
        progress.ownedItems.values.map {
            CollectionItem(
                id: "item-\($0.itemID)",
                name: $0.name,
                imageName: $0.imageName,
                rarity: $0.rarity,
                levelTitle: "Lv \($0.level)",
                stars: nil,
                isSelected: false,
                canSelect: false,
                character: nil,
                skin: nil
            )
        }
        .sorted { sortedCollectionItem($0, before: $1) }
    }

    private func select(_ item: CollectionItem) {
        if let character = item.character,
            let skin = item.skin
        {
            progress.selectSkin(skin, for: character)
        } else if let character = item.character {
            progress.selectCharacter(character)
        }
    }

    private func sortedCollectionItem(
        _ first: CollectionItem,
        before second: CollectionItem
    ) -> Bool {
        if first.rarity.sortRank == second.rarity.sortRank {
            return first.name < second.name
        }

        return first.rarity.sortRank > second.rarity.sortRank
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func collectionCard(_ item: CollectionItem) -> some View {
        VStack(spacing: 8) {
            RemoteImage(name: item.imageName)
                .frame(width: 58, height: 58)

            Text(item.name)
                .font(.system(size: 11, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )

            if let stars = item.stars {
                StarRatingView(stars: stars, maxVisibleStars: 7, size: 8)
            } else if let levelTitle = item.levelTitle {
                Text(levelTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(item.rarity.color)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )
            }
        }
        .foregroundStyle(.white)
        .opacity(
            item.canSelect || item.stars != nil || item.levelTitle != "Locked"
                ? 1 : 0.45
        )
        .frame(maxWidth: .infinity)
        .frame(height: 118)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    item.isSelected ? .white : item.rarity.color.opacity(0.75),
                    lineWidth: item.isSelected ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }
}

private struct CollectionItem: Identifiable {
    let id: String
    let name: String
    let imageName: String
    let rarity: SpriteRarity
    let levelTitle: String?
    let stars: Int?
    let isSelected: Bool
    let canSelect: Bool
    let character: CharacterDefinition?
    let skin: CharacterSkin?
}

private enum SpriteCollectionCategory: CaseIterable {
    case characters
    case skins
    case companions
    case relics
    case items

    var title: String {
        switch self {
        case .characters:
            "Characters"
        case .skins:
            "Skins"
        case .companions:
            "Companions"
        case .relics:
            "Relics"
        case .items:
            "Items"
        }
    }

    var imageName: String {
        switch self {
        case .characters:
            "icon_nimpi"
        case .skins:
            "icon_pixel_sprite"
        case .companions:
            "icon_pixel_box"
        case .relics:
            "icon_pixel_relic"
        case .items:
            "icon_pixel_sword"
        }
    }
}

extension SpriteRarity {
    fileprivate var sortRank: Int {
        switch self {
        case .common:
            0
        case .rare:
            1
        case .epic:
            2
        case .legendary:
            3
        }
    }
}

#Preview {
    SpriteListView(progress: GameProgressStore())
}
