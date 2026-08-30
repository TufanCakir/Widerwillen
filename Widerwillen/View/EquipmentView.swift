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

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                LazyVStack(spacing: 12) {
                    GameHeader(progress: progress)
                        .padding(.top, 18)

                    equipmentLoadout
                    skinEquipmentSection
                    weaponEquipmentSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
        }
    }

    private var equipmentLoadout: some View {
        HStack(spacing: 14) {
            loadoutSlot(
                title: "Skin",
                imageName: progress.selectedCharacterSkin?.imageName
                    ?? "icon_nimpi",
                subtitle: progress.selectedCharacterSkin?.name ?? "Default"
            )

            VStack(spacing: 6) {
                RemoteImage(
                    name: progress.selectedCharacterSkin?.imageName
                        ?? "icon_nimpi"
                )
                .frame(width: 72, height: 72)

                Text(progress.selectedCharacter?.name ?? "Nimbi")
                    .widerwillenFont(size: 14, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            loadoutSlot(
                title: "Weapon",
                imageName: progress.equippedWeapon?.imageName
                    ?? "icon_pixel_sword",
                subtitle: progress.equippedWeapon?.name ?? "Empty",
                isEmpty: progress.equippedWeapon == nil
            )
        }
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func loadoutSlot(
        title: String,
        imageName: String,
        subtitle: String,
        isEmpty: Bool = false
    ) -> some View {
        VStack(spacing: 7) {
            Text(title)
                .widerwillenFont(size: 10, weight: .heavy)
                .foregroundStyle(.white.opacity(0.72))

            RemoteImage(name: imageName)
                .frame(width: 46, height: 46)
                .opacity(isEmpty ? 0.42 : 1)

            Text(subtitle)
                .widerwillenFont(size: 9, weight: .bold)
                .foregroundStyle(.white.opacity(isEmpty ? 0.52 : 0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(width: 96, height: 104)
        .background(.white.opacity(isEmpty ? 0.05 : 0.1))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(isEmpty ? 0.24 : 0.62), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var skinEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Skins")

            ForEach(unlockedSkins) { entry in
                equipmentCard(
                    title: entry.skin.name,
                    imageName: entry.skin.imageName,
                    subtitle: entry.character.name,
                    valueText: "Skin",
                    rarity: entry.character.rarity,
                    isEquipped: progress.isSelectedSkin(entry.skin),
                    actionTitle: progress.isSelectedSkin(entry.skin)
                        ? "Equipped"
                        : "Equip"
                ) {
                    playSoundEffect("ui_confirm")
                    progress.selectSkin(entry.skin, for: entry.character)
                }
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

private struct EquipmentSkinEntry: Identifiable {
    var id: String { skin.id }

    let character: CharacterDefinition
    let skin: CharacterSkin
}

#Preview {
    EquipmentView(progress: GameProgressStore()) { _ in }
}
