//
//  StarRatingView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct StarRatingView: View {
    let stars: Int
    var maxVisibleStars = 7
    var size: CGFloat = 9

    private let configuration =
        (try? StarsConfiguration.load()) ?? StarsConfiguration.fallback

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<visibleStarCount, id: \.self) { index in
                Image(
                    systemName: index < filledVisibleStars
                        ? configuration.filledSystemImage
                        : configuration.emptySystemImage
                )
                .font(.system(size: size, weight: .heavy))
            }

            if stars > maxVisibleStars {
                Text("+\(stars - maxVisibleStars)")
                    .font(.system(size: size, weight: .heavy))
            }
        }
        .foregroundStyle(configuration.color(for: stars))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
    }

    private var clampedStars: Int {
        min(max(stars, 0), configuration.maxStars)
    }

    private var visibleStarCount: Int {
        min(configuration.maxStars, maxVisibleStars)
    }

    private var filledVisibleStars: Int {
        min(clampedStars, visibleStarCount)
    }
}

#Preview {
    ZStack {
        AppBackground()
        StarRatingView(stars: 10)
    }
}
