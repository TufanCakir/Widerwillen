//
//  BattleCardBar.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct BattleCardBar: View {
    let progress: GameProgressStore
    let battleCards: BattleCardConfiguration
    let activeSkills: [BattleActiveSkill]
    let activeSkillIDs: Set<String>
    let cooldownClockDate: Date
    let cardCooldownEndDates: [String: Date]
    let skillCooldownEndDates: [String: Date]
    let onCardAttack: (BattleCardDefinition) -> Void
    let onSkillActivation: (BattleActiveSkill) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(unlockedBattleCards) { card in
                    BattleCardButton(
                        card: card,
                        cooldownRemaining: cardCooldownRemaining(for: card.id),
                        isActive: false
                    ) {
                        onCardAttack(card)
                    }
                }

                ForEach(activeSkills) { skill in
                    let card = cardDefinition(for: skill.id)
                    let isActive = activeSkillIDs.contains(skill.id)

                    BattleCardButton(
                        card: card,
                        fallbackTitle: skill.title,
                        fallbackImageName: skill.imageName,
                        cooldownRemaining: skillCooldownRemaining(for: skill.id),
                        isActive: isActive
                    ) {
                        onSkillActivation(skill)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
    }

    private var unlockedBattleCards: [BattleCardDefinition] {
        battleCards.cards.filter { card in
            guard card.id != "shadow_clone_active" else { return false }
            guard let skillID = card.requiredSkillID else { return true }

            return progress.skillLevel(forSkillID: skillID) >= card.requiredSkillLevel
        }
    }

    private func cardDefinition(for id: String) -> BattleCardDefinition? {
        battleCards.cards.first { $0.id == id }
    }

    private func cardCooldownRemaining(for id: String) -> TimeInterval {
        max(cardCooldownEndDates[id]?.timeIntervalSince(cooldownClockDate) ?? 0, 0)
    }

    private func skillCooldownRemaining(for id: String) -> TimeInterval {
        max(skillCooldownEndDates[id]?.timeIntervalSince(cooldownClockDate) ?? 0, 0)
    }
}

private struct BattleCardButton: View {
    let card: BattleCardDefinition?
    var fallbackTitle = "Tab"
    var fallbackImageName = "icon_pixel_sword"
    let cooldownRemaining: TimeInterval
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                background

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(title)
                            .widerwillenFont(size: 13, weight: .heavy)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Spacer(minLength: 4)

                        Text(style)
                            .widerwillenFont(size: 9, weight: .heavy)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(.white.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }

                    BattleCardMovePreview(move: move, fallbackImageName: imageName)
                        .frame(width: 80, height: 64)
                        .clipped()

                    HStack(spacing: 8) {
                        Text("DMG x\(damageText(damageMultiplier))")
                        Text("STA \(staminaCost)")
                    }
                    .widerwillenFont(size: 10, weight: .heavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 1)

                if isCoolingDown {
                    Color.black.opacity(0.64)

                    VStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .heavy))

                        Text("\(Int(ceil(cooldownRemaining)))s")
                            .widerwillenFont(size: 15, weight: .heavy)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 1)
                }
            }
            .frame(width: 142, height: 138)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isActive ? .cyan : .white.opacity(0.7),
                        lineWidth: isActive ? 3 : 1
                    )
            }
            .shadow(color: .black.opacity(0.82), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isCoolingDown || isActive)
        .opacity(isCoolingDown ? 0.68 : 1)
    }

    private var title: String { card?.title ?? fallbackTitle }
    private var imageName: String { card?.imageName ?? fallbackImageName }
    private var gradientColors: [String] { card?.gradientColors ?? [] }
    private var move: BattleCardMove { card?.move ?? .punch }
    private var style: String { card?.style ?? "Strike" }
    private var staminaCost: Int { card?.staminaCost ?? 0 }
    private var damageMultiplier: Double { card?.damageMultiplier ?? 1 }
    private var isCoolingDown: Bool { cooldownRemaining > 0 }

    @ViewBuilder
    private var background: some View {
        if let cardImageName = card?.cardImageName {
            RemoteImage(name: cardImageName, contentMode: .fill)
                .frame(width: 142, height: 138)
                .clipped()
        } else if let backgroundImageName = card?.backgroundImageName {
            RemoteImage(name: backgroundImageName, contentMode: .fill)
                .frame(width: 142, height: 138)
                .clipped()
        } else {
            LinearGradient(
                colors: colors(from: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func damageText(_ multiplier: Double) -> String {
        if multiplier.rounded() == multiplier {
            return "\(Int(multiplier))"
        }

        return String(format: "%.1f", multiplier)
    }

    @MainActor
    private func colors(from hexValues: [String]) -> [Color] {
        let colors = hexValues.map(Color.init(hex:))
        return colors.isEmpty ? [.white, .cyan] : colors
    }
}

private struct BattleCardMovePreview: View {
    let move: BattleCardMove
    let fallbackImageName: String

    var body: some View {
        ZStack {
            part("sprite_nimbi_original_left_foot", z: 0)
                .offset(pose.leftFootOffset)
                .rotationEffect(pose.leftFootRotation)

            part("sprite_nimbi_original_right_foot", z: 1)
                .offset(pose.rightFootOffset)
                .rotationEffect(pose.rightFootRotation)

            part("sprite_nimbi_original_body", z: 2)
                .rotationEffect(pose.bodyRotation)

            part("sprite_nimbi_original_left_hand", z: 3)
                .offset(pose.leftHandOffset)
                .rotationEffect(pose.leftHandRotation)

            part("sprite_nimbi_original_right_hand", z: 4)
                .offset(pose.rightHandOffset)
                .rotationEffect(pose.rightHandRotation)

            part("sprite_original_slenderize_sword", z: 5, size: 16)
                .offset(pose.weaponOffset)
                .rotationEffect(pose.weaponRotation)

            part("sprite_nimbi_original_head", z: 6)
                .offset(pose.headOffset)
                .rotationEffect(pose.headRotation)
        }
        .scaleEffect(pose.scale)
        .rotationEffect(pose.characterRotation)
        .offset(pose.characterOffset)
    }

    private func part(
        _ imageName: String,
        z: Double,
        size: CGFloat = 32
    ) -> some View {
        RemoteImage(
            name: imageName,
            placeholderColor: .white.opacity(0.14),
            fallbackSystemImage: fallbackImageName
        )
        .frame(width: size, height: size)
        .zIndex(z)
    }

    private var pose: BattleCardPreviewPose {
        BattleCardPreviewPose(move: move)
    }
}

private struct BattleCardPreviewPose {
    var scale: CGFloat = 1.7
    var characterOffset = CGSize.zero
    var characterRotation = Angle.zero
    var bodyRotation = Angle.zero
    var headOffset = CGSize.zero
    var headRotation = Angle.zero
    var leftHandOffset = CGSize.zero
    var leftHandRotation = Angle.zero
    var rightHandOffset = CGSize.zero
    var rightHandRotation = Angle.zero
    var weaponOffset = CGSize(width: 9, height: -2)
    var weaponRotation = Angle.degrees(-18)
    var leftFootOffset = CGSize.zero
    var leftFootRotation = Angle.zero
    var rightFootOffset = CGSize.zero
    var rightFootRotation = Angle.zero

    init(move: BattleCardMove) {
        switch move {
        case .punch:
            rightHandOffset = CGSize(width: 11, height: -2)
            rightHandRotation = .degrees(-28)
            leftHandOffset = CGSize(width: -2, height: -3)
            leftHandRotation = .degrees(16)
            weaponOffset = CGSize(width: 15, height: -4)
            weaponRotation = .degrees(-38)
            bodyRotation = .degrees(-5)
        case .kick:
            rightFootOffset = CGSize(width: 12, height: 5)
            rightFootRotation = .degrees(-24)
            leftFootOffset = CGSize(width: -2, height: 1)
            bodyRotation = .degrees(4)
        case .dash:
            characterOffset = CGSize(width: 9, height: -1)
            scale = 1.6
            rightHandOffset = CGSize(width: 4, height: 0)
            weaponOffset = CGSize(width: 11, height: -2)
            weaponRotation = .degrees(-32)
            bodyRotation = .degrees(-8)
        case .tornado:
            characterOffset = CGSize(width: 2, height: -4)
            characterRotation = .degrees(28)
            weaponOffset = CGSize(width: 8, height: -2)
            weaponRotation = .degrees(-60)
            rightFootOffset = CGSize(width: 12, height: 7)
            rightFootRotation = .degrees(-54)
            leftFootRotation = .degrees(24)
        case .roundhouse:
            rightFootOffset = CGSize(width: 14, height: 5)
            rightFootRotation = .degrees(-64)
            leftHandRotation = .degrees(24)
            weaponOffset = CGSize(width: 8, height: -1)
            weaponRotation = .degrees(12)
            bodyRotation = .degrees(10)
        case .airSpin:
            characterOffset = CGSize(width: 0, height: -5)
            characterRotation = .degrees(180)
            rightHandRotation = .degrees(-28)
            weaponOffset = CGSize(width: 7, height: -1)
            weaponRotation = .degrees(-54)
            leftHandRotation = .degrees(28)
            rightFootRotation = .degrees(-24)
            leftFootRotation = .degrees(24)
        }
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: cleaned)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
