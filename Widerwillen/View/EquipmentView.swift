//
//  EquipmentView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct EquipmentView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    @State private var selectedCategory = EquipmentCategory.wardrobe.rawValue
    @State private var selectedPart: CharacterBodyPart = .head

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                LazyVStack(spacing: 14) {
                    GameHeader(progress: progress)
                        .padding(.top, 18)

                    equipmentLoadout
                    categoryBar
                    selectedCategoryContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
        }
    }

    private var equipmentLoadout: some View {
        HStack(spacing: 10) {
            bodyPartColumn(parts: [.head, .rightHand, .rightFoot])

            VStack(spacing: 9) {
                RemoteImage(
                    name: progress.selectedCharacterSkin?.imageName
                        ?? "icon_nimpi"
                )
                .frame(width: 92, height: 92)
                .padding(18)
                .background(.black.opacity(0.24))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.cyan.opacity(0.45), lineWidth: 2)
                }

                Text(progress.selectedCharacter?.name ?? "Nimbi")
                    .widerwillenFont(size: 18, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(progress.selectedCharacterSkin?.name ?? "Default")
                    .widerwillenFont(size: 11, weight: .bold)
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)

            bodyPartColumn(parts: [.body, .leftHand, .leftFoot])
        }
        .padding(12)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func bodyPartColumn(parts: [CharacterBodyPart]) -> some View {
        VStack(spacing: 8) {
            ForEach(parts) { part in
                bodyPartSlot(part)
            }
        }
        .frame(width: 96)
    }

    private func bodyPartSlot(_ part: CharacterBodyPart) -> some View {
        let skin = progress.selectedSkin(for: part)
        let hasOverride =
            progress.selectedCharacterPartSkinIDs[part.rawValue] != nil

        return Button {
            playSoundEffect("ui_select")
            selectedPart = part
            selectedCategory = EquipmentCategory.parts.rawValue
        } label: {
            VStack(spacing: 5) {
                Text(part.title)
                    .widerwillenFont(size: 8, weight: .heavy)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                RemoteImage(name: progress.imageName(for: part, skin: skin))
                    .frame(width: 34, height: 34)

                Text(hasOverride ? skin?.name ?? "Mix" : "Base")
                    .widerwillenFont(size: 8, weight: .bold)
                    .foregroundStyle(.white.opacity(hasOverride ? 0.9 : 0.54))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 88, height: 78)
            .background(
                hasOverride ? .white.opacity(0.12) : .black.opacity(0.18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedPart == part
                            && selectedCategory
                                == EquipmentCategory.parts.rawValue
                            ? .cyan.opacity(0.95)
                            : .blue.opacity(hasOverride ? 0.75 : 0.38),
                        lineWidth: selectedPart == part
                            && selectedCategory
                                == EquipmentCategory.parts.rawValue
                            ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var categoryBar: some View {
        CategoryBar(
            categories: EquipmentCategory.allCases.map(\.rawValue),
            selectedCategory: $selectedCategory,
            playSoundEffect: playSoundEffect
        ) { category in
            EquipmentCategory(rawValue: category)?.title ?? category
        }
    }

    @ViewBuilder
    private var selectedCategoryContent: some View {
        switch EquipmentCategory(rawValue: selectedCategory) ?? .wardrobe {
        case .wardrobe:
            skinEquipmentSection
        case .parts:
            skinPartEquipmentSection
        case .weapons:
            weaponEquipmentSection
        }
    }

    private var skinEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Wardrobe")

            ForEach(unlockedSkins) { entry in
                equipmentCard(
                    title: entry.skin.name,
                    imageName: entry.skin.imageName,
                    subtitle: "Complete skin",
                    valueText: "All",
                    rarity: entry.character.rarity,
                    isEquipped: progress.isSelectedSkin(entry.skin)
                        && progress.selectedCharacterPartSkinIDs.isEmpty,
                    actionTitle: progress.isSelectedSkin(entry.skin)
                        && progress.selectedCharacterPartSkinIDs.isEmpty
                        ? "Equipped"
                        : "Equip"
                ) {
                    playSoundEffect("ui_confirm")
                    progress.selectSkin(entry.skin, for: entry.character)
                }
            }
        }
    }

    private var skinPartEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(selectedPart.title)
            partPicker

            Button {
                playSoundEffect("ui_confirm")
                progress.clearSkinPart(selectedPart)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .heavy))

                    Text("Use Wardrobe Skin")
                        .widerwillenFont(size: 14, weight: .heavy)

                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(14)
                .background(.black.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.blue.opacity(0.52), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            ForEach(unlockedSkins) { entry in
                equipmentCard(
                    title: entry.skin.name,
                    imageName: progress.imageName(
                        for: selectedPart,
                        skin: entry.skin
                    ),
                    subtitle: "Apply to \(selectedPart.title)",
                    valueText: "Part",
                    rarity: entry.character.rarity,
                    isEquipped: progress.isSelectedSkin(
                        entry.skin,
                        for: selectedPart
                    ),
                    actionTitle: progress.isSelectedSkin(
                        entry.skin,
                        for: selectedPart
                    ) ? "Equipped" : "Use"
                ) {
                    playSoundEffect("ui_confirm")
                    progress.selectSkinPart(entry.skin, for: selectedPart)
                }
            }
        }
    }

    private var partPicker: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ],
            spacing: 8
        ) {
            ForEach(CharacterBodyPart.allCases) { part in
                Button {
                    playSoundEffect("ui_select")
                    selectedPart = part
                } label: {
                    VStack(spacing: 3) {
                        RemoteImage(name: progress.imageName(for: part))
                            .frame(width: 24, height: 24)

                        Text(part.title)
                            .widerwillenFont(size: 8, weight: .heavy)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        selectedPart == part
                            ? .white.opacity(0.18)
                            : .black.opacity(0.20)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                selectedPart == part
                                    ? .cyan.opacity(0.92)
                                    : .blue.opacity(0.44),
                                lineWidth: selectedPart == part ? 2 : 1
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weaponEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Weapons")

            if progress.ownedItems.isEmpty {
                emptyState(
                    imageName: "icon_pixel_box",
                    title: "No equipment"
                )
            } else {
                ForEach(
                    Array(progress.ownedItems.values)
                        .sorted { $0.name < $1.name }
                ) { item in
                    equipmentCard(
                        title: item.name,
                        imageName: item.imageName,
                        subtitle: "Lv \(item.level)",
                        valueText: "+\(item.damageBonus)",
                        rarity: item.rarity,
                        isEquipped: progress.isEquippedWeapon(item),
                        actionTitle: progress.isEquippedWeapon(item)
                            ? "Equipped"
                            : "Equip"
                    ) {
                        playSoundEffect("ui_confirm")
                        progress.equipWeapon(item)
                    }
                }
            }

            sectionHeader("Weapon Skins")
                .padding(.top, 4)

            Button {
                playSoundEffect("ui_confirm")
                progress.clearWeaponSkin()
            } label: {
                HStack(spacing: 12) {
                    RemoteImage(
                        name: progress.equippedWeapon?.imageName
                            ?? "icon_pixel_sword"
                    )
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Use Weapon Look")
                            .widerwillenFont(size: 14, weight: .heavy)

                        Text(progress.equippedWeapon?.name ?? "Default")
                            .widerwillenFont(size: 10, weight: .bold)
                            .opacity(0.68)
                    }

                    Spacer()

                    Text(
                        progress.equippedWeaponSkin == nil ? "Equipped" : "Use"
                    )
                    .widerwillenFont(size: 10, weight: .heavy)
                    .foregroundStyle(
                        progress.equippedWeaponSkin == nil ? .black : .white
                    )
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(
                        progress.equippedWeaponSkin == nil
                            ? .white
                            : .white.opacity(0.14)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    progress.equippedWeaponSkin == nil
                        ? .white.opacity(0.12)
                        : .black.opacity(0.18)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.blue.opacity(0.72), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(progress.equippedWeaponSkin == nil)

            if progress.ownedWeaponSkinList.isEmpty {
                emptyState(
                    imageName: "icon_pixel_sword",
                    title: "No weapon skins"
                )
            } else {
                ForEach(progress.ownedWeaponSkinList) { skin in
                    equipmentCard(
                        title: skin.name,
                        imageName: skin.imageName,
                        subtitle: "Cosmetic weapon look",
                        valueText: "Skin",
                        rarity: skin.rarity,
                        isEquipped: progress.isEquippedWeaponSkin(skin),
                        actionTitle: progress.isEquippedWeaponSkin(skin)
                            ? "Equipped"
                            : "Use"
                    ) {
                        playSoundEffect("ui_confirm")
                        progress.equipWeaponSkin(skin)
                    }
                }
            }
        }
    }

    private var unlockedSkins: [EquipmentSkinEntry] {
        progress.characterDefinitions.flatMap { character in
            character.skins.compactMap { skin in
                guard progress.isSkinUnlocked(skin),
                    progress.ownedCharacterList.contains(where: {
                        $0.characterID == character.id
                    })
                else {
                    return nil
                }

                return EquipmentSkinEntry(character: character, skin: skin)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .widerwillenFont(size: 15, weight: .heavy)
            .foregroundStyle(.white.opacity(0.86))
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func equipmentCard(
        title: String,
        imageName: String,
        subtitle: String,
        valueText: String,
        rarity: SpriteRarity? = nil,
        isEquipped: Bool = false,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            RemoteImage(name: imageName)
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .widerwillenFont(size: 17, weight: .heavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .widerwillenFont(size: 11, weight: .bold)
                    .opacity(0.68)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            Text(valueText)
                .widerwillenFont(size: 15, weight: .heavy)

            Button(action: action) {
                Text(actionTitle)
                    .widerwillenFont(size: 10, weight: .heavy)
                    .foregroundStyle(isEquipped ? .black : .white)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(isEquipped ? .white : .white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isEquipped)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        .padding(14)
        .background(isEquipped ? .white.opacity(0.12) : .black.opacity(0.18))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isEquipped
                        ? .blue.opacity(0.9)
                        : (rarity?.color ?? .blue).opacity(0.62),
                    lineWidth: isEquipped ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func emptyState(imageName: String, title: String) -> some View {
        VStack(spacing: 12) {
            RemoteImage(name: imageName)
                .frame(width: 58, height: 58)
                .opacity(0.45)

            Text(title)
                .widerwillenFont(size: 16, weight: .heavy)
                .foregroundStyle(.white.opacity(0.72))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }
}

private enum EquipmentCategory: String, CaseIterable, Identifiable {
    case wardrobe
    case parts
    case weapons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wardrobe:
            "Wardrobe"
        case .parts:
            "Parts"
        case .weapons:
            "Weapons"
        }
    }
}

private struct EquipmentSkinEntry: Identifiable {
    var id: String { skin.id }

    let character: CharacterDefinition
    let skin: CharacterSkin
}

#Preview {
    EquipmentView(progress: GameProgressStore()) { _ in }
}
