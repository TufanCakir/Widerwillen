//
//  SummonResultView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct SummonResultView: View {
    let results: [SummonResult]
    let onClose: () -> Void

    @State private var revealedCount = 0

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                header

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(results.enumerated()), id: \.element.id) {
                            index,
                            result in
                            resultCard(result, index: index)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                }

                closeButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .padding(.top, 28)
        }
        .statusBarHidden(true)
        .task {
            await revealResults()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Summon Result")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

            Text("\(results.count) rewards")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.78))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        }
    }

    private func resultCard(_ result: SummonResult, index: Int) -> some View {
        let isRevealed = index < revealedCount

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(result.entry.rarity.color.opacity(0.22))
                    .blur(radius: isRevealed ? 2 : 0)
                    .scaleEffect(isRevealed ? 1.18 : 0.4)

                RemoteImage(name: result.entry.imageName)
                    .frame(width: 58, height: 58)
                    .scaleEffect(isRevealed ? 1 : 0.2)
                    .opacity(isRevealed ? 1 : 0)
            }
            .frame(width: 72, height: 72)

            Text(result.entry.name)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

            if result.kind == .sprite {
                StarRatingView(stars: result.level, maxVisibleStars: 7, size: 8)
            } else {
                Text(result.isDuplicate ? "Duplicate  Lv \(result.level)" : "New  Lv 1")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }

            Text(result.entry.rarity.title)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(result.entry.rarity.color)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 146)
        .padding(8)
        .background(.black.opacity(isRevealed ? 0.34 : 0.18))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    result.entry.rarity.color.opacity(isRevealed ? 0.86 : 0.25),
                    lineWidth: result.entry.rarity == .legendary ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(
            color: result.entry.rarity.color.opacity(isRevealed ? 0.46 : 0),
            radius: isRevealed ? 10 : 0,
            x: 0,
            y: 0
        )
        .scaleEffect(isRevealed ? 1 : 0.86)
        .opacity(isRevealed ? 1 : 0.28)
        .animation(
            .spring(response: 0.34, dampingFraction: 0.72),
            value: revealedCount
        )
    }

    private var closeButton: some View {
        Button {
            onClose()
        } label: {
            Text("Continue")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.black.opacity(0.56))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.74), lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(revealedCount < results.count)
        .opacity(revealedCount < results.count ? 0.45 : 1)
    }

    private func revealResults() async {
        revealedCount = 0

        for index in results.indices {
            try? await Task.sleep(for: .milliseconds(index == results.startIndex ? 180 : 130))
            await MainActor.run {
                revealedCount = index + 1
            }
        }
    }
}

#Preview {
    SummonResultView(results: [], onClose: {})
}
