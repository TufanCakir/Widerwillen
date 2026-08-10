//
//  SpriteListView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct SpriteListView: View {
    let progress: GameProgressStore

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 14)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(collectionItems) { item in
                        collectionCard(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .padding(.bottom, 90)
            }
        }
    }

    private var collectionItems: [CollectionItem] {
        let sprites = progress.ownedSprites.values.map {
            CollectionItem(
                id: "sprite-\($0.spriteIndex)",
                name: $0.name,
                imageName: $0.imageName,
                rarity: $0.rarity,
                levelTitle: "Star \($0.stars)"
            )
        }

        let relics = progress.ownedArtifacts.values.map {
            CollectionItem(
                id: "relic-\($0.artifactID)",
                name: $0.name,
                imageName: $0.imageName,
                rarity: $0.rarity,
                levelTitle: "Lv \($0.level)"
            )
        }

        let items = progress.ownedItems.values.map {
            CollectionItem(
                id: "item-\($0.itemID)",
                name: $0.name,
                imageName: $0.imageName,
                rarity: $0.rarity,
                levelTitle: "Lv \($0.level)"
            )
        }

        return (sprites + relics + items).sorted {
            if $0.rarity.sortRank == $1.rarity.sortRank {
                return $0.name < $1.name
            }

            return $0.rarity.sortRank > $1.rarity.sortRank
        }
    }

    private func collectionCard(_ item: CollectionItem) -> some View {
        VStack(spacing: 8) {
            Image(item.imageName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
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

            Text(item.levelTitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(item.rarity.color)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 118)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.rarity.color.opacity(0.75), lineWidth: 1)
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
    let levelTitle: String
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
