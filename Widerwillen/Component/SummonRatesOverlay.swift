//
//  SummonRatesOverlay.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct SummonRatesOverlay: View {
    let banner: SummonBanner
    let onClose: () -> Void

    @State private var selectedID: String?
    @Environment(\.locale) private var locale

    private var outcomes: [SummonDistribution.Outcome] {
        SummonDistribution(entries: banner.entries).outcomes
    }

    private var selectedIndex: Int {
        outcomes.firstIndex { $0.id == selectedID } ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("BANNER DATABASE")
                                .font(.caption.monospaced().weight(.bold))
                                .tracking(2)
                                .foregroundStyle(.cyan)
                            Text(banner.title)
                                .widerwillenFont(size: 22, weight: .heavy)
                        }
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.08), in: Circle())
                        }
                        .accessibilityLabel("Close")
                    }

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)

                    if outcomes.isEmpty {
                        ContentUnavailableView(
                            "No banner contents",
                            systemImage: "square.stack"
                        )
                    } else {
                        TabView(selection: $selectedID) {
                            ForEach(outcomes) { outcome in
                                entryCard(outcome)
                                    .padding(.horizontal, 4)
                                    .tag(Optional(outcome.id))
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))

                        HStack {
                            Button {
                                moveSelection(by: -1)
                            } label: {
                                Image(systemName: "chevron.left").frame(
                                    width: 44,
                                    height: 44
                                )
                            }
                            .disabled(selectedIndex == 0)
                            .accessibilityLabel("Previous item")
                            Spacer()
                            Text("\(selectedIndex + 1) / \(outcomes.count)")
                                .font(
                                    .subheadline.monospacedDigit().weight(
                                        .semibold
                                    )
                                )
                            Spacer()
                            Button {
                                moveSelection(by: 1)
                            } label: {
                                Image(systemName: "chevron.right").frame(
                                    width: 44,
                                    height: 44
                                )
                            }
                            .disabled(selectedIndex == outcomes.count - 1)
                            .accessibilityLabel("Next item")
                        }
                        .tint(.cyan)
                    }

                    Text("Chance per draw · Same rates for Single and Multi")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding(20)
                .frame(maxWidth: 480)
                .frame(height: max(220, min(620, geometry.size.height - 24)))
                .background {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.025, green: 0.16, blue: 0.32),
                                    Color(red: 0.015, green: 0.045, blue: 0.12),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .cyan.opacity(0.8), .blue.opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)
                }
                .shadow(color: .blue.opacity(0.25), radius: 25)
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { selectedID = outcomes.first?.id }
        .accessibilityAddTraits(.isModal)
    }

    private func entryCard(_ outcome: SummonDistribution.Outcome) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Text(outcome.entry.rarity.title)
                        .foregroundStyle(outcome.entry.rarity.color)
                    Spacer()
                    Image(systemName: "sparkles").foregroundStyle(.cyan)
                }
                .font(.caption.monospaced().weight(.bold))

                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.12))
                    Circle()
                        .stroke(
                            .cyan.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 7])
                        )
                    RemoteImage(name: outcome.entry.imageName)
                        .padding(25)
                        .shadow(
                            color: outcome.entry.rarity.color.opacity(0.35),
                            radius: 20
                        )
                }
                .frame(width: 150, height: 150)

                Text(outcome.entry.name)
                    .widerwillenFont(size: 24, weight: .heavy)
                    .multilineTextAlignment(.center)

                VStack(spacing: 5) {
                    Text("DROP CHANCE").font(
                        .caption.monospaced().weight(.bold)
                    ).foregroundStyle(.cyan)
                    Text(rateText(outcome.probability))
                        .font(
                            .system(
                                .largeTitle,
                                design: .rounded,
                                weight: .bold
                            )
                        )
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(
                    .cyan.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .padding(18)
        }
        .background(
            .black.opacity(0.16),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20).stroke(
                .cyan.opacity(0.15),
                lineWidth: 1
            )
        }
    }

    private func rateText(_ probability: Double) -> String {
        let style = FloatingPointFormatStyle<Double>.Percent
            .percent.precision(.fractionLength(0...2)).locale(locale)
        if probability > 0 && probability < 0.0001 {
            return "< " + 0.0001.formatted(style)
        }
        return probability.formatted(style)
    }

    private func moveSelection(by offset: Int) {
        let index = selectedIndex + offset
        guard outcomes.indices.contains(index) else { return }
        withAnimation { selectedID = outcomes[index].id }
    }
}
