//
//  RigUpgradeView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct RigUpgradeView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let configuration =
        (try? RigUpgradeConfiguration.load())
        ?? RigUpgradeConfiguration(parts: [])

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rig-Upgrades")
                .widerwillenFont(size: 15, weight: .heavy)
                .foregroundStyle(.white.opacity(0.86))

            Text(
                "Verbessere einzelne Körperteile. Höhere Level verstärken Metallglanz und Partikel direkt im Kampf."
            )
            .widerwillenFont(size: 10, weight: .bold)
            .foregroundStyle(.white.opacity(0.62))

            ForEach(configuration.parts) { part in
                upgradeCard(part)
            }
        }
    }

    private func upgradeCard(_ part: RigUpgradePart) -> some View {
        let level = progress.rigUpgradeLevel(for: part.id)
        let currentEffect = part.levels.first { $0.level == level }
        let nextLevel = part.levels.first { $0.level == level + 1 }

        return HStack(spacing: 12) {
            ZStack {
                RemoteImage(name: imageName(for: part))
                    .frame(width: 48, height: 48)
                    .overlay {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(
                                    currentEffect?.glowIntensity ?? 0
                                ), .clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.screen)
                    }

                if level >= 2 {
                    Image(systemName: "sparkles")
                        .font(
                            .system(size: CGFloat(9 + level * 2), weight: .bold)
                        )
                        .foregroundStyle(level >= 4 ? .yellow : .cyan)
                        .shadow(color: .white, radius: CGFloat(level))
                }
            }
            .frame(width: 58, height: 58)
            .background(.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(part.title)
                    .widerwillenFont(size: 15, weight: .heavy)
                    .foregroundStyle(.white)
                Text("Level \(level) / \(part.levels.count)")
                    .widerwillenFont(size: 10, weight: .bold)
                    .foregroundStyle(.cyan.opacity(0.86))
                Text(effectDescription(level: level))
                    .widerwillenFont(size: 8, weight: .bold)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            Button {
                if progress.upgradeRigPart(part) {
                    playSoundEffect("ui_confirm")
                } else {
                    playSoundEffect("ui_error")
                }
            } label: {
                VStack(spacing: 3) {
                    Text(nextLevel == nil ? "MAX" : "Upgrade")
                    if let nextLevel {
                        Text("\(nextLevel.cost) Münzen")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                .widerwillenFont(size: 9, weight: .heavy)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(minWidth: 72, minHeight: 36)
                .background(
                    canAfford(nextLevel)
                        ? .blue.opacity(0.65) : .gray.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(nextLevel == nil || !canAfford(nextLevel))
        }
        .padding(12)
        .background(.black.opacity(0.2))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(0.55), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func canAfford(_ level: RigUpgradeLevel?) -> Bool {
        guard let level else { return false }
        return progress.coins >= level.cost
    }

    private func imageName(for part: RigUpgradePart) -> String {
        if part.id == "weapon" {
            return progress.equippedWeaponImageName ?? part.imageFallback
        }
        guard let bodyPart = CharacterBodyPart(rawValue: part.id) else {
            return part.imageFallback
        }
        return progress.imageName(for: bodyPart)
    }

    private func effectDescription(level: Int) -> String {
        switch level {
        case 0: "Noch kein Effekt"
        case 1: "Leichter Metallglanz"
        case 2: "Metallglanz + Funken"
        case 3: "Starker Shader + Aura"
        case 4: "Epische Metallpartikel"
        default: "Maximaler legendärer Effekt"
        }
    }
}
