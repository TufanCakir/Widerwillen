//
//  AppBackground.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct AppBackground: View {

    @AppStorage("selectedMenuBackgroundID")
    private var selectedMenuBackgroundID =
        MenuBackgroundConfiguration.defaultBackgroundID

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private let configuration =
        (try? MenuBackgroundConfiguration.load())
        ?? MenuBackgroundConfiguration.fallback

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                baseGradient

                if let imageName = selectedBackground.imageName {
                    RemoteImage(
                        name: imageName,
                        contentMode: .fill
                    )
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .clipped()
                }

                if selectedBackground.usesAnimatedRings && !reduceMotion {
                    rotatingBackgroundRings
                }

                darknessOverlay
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var selectedBackground: MenuBackgroundDefinition {
        configuration.backgrounds.first {
            $0.id == selectedMenuBackgroundID
        }
        ?? configuration.backgrounds.first
        ?? MenuBackgroundConfiguration.fallback.backgrounds[0]
    }

    private var baseGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.008, green: 0.027, blue: 0.075),
                Color(red: 0.027, green: 0.114, blue: 0.227),
                Color(red: 0.039, green: 0.310, blue: 0.620),
                Color(red: 0.012, green: 0.082, blue: 0.169),
                Color(red: 0.000, green: 0.016, blue: 0.039)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var darknessOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.70),
                .black.opacity(0.08),
                .black.opacity(
                    min(
                        0.96,
                        0.82 + selectedBackground.darkening
                    )
                )
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var rotatingBackgroundRings: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            if side > 220 {
                TimelineView(.animation) { timeline in
                    let seconds =
                        timeline.date.timeIntervalSinceReferenceDate

                    let clockwiseDegrees =
                        (seconds * 100)
                        .truncatingRemainder(dividingBy: 360)

                    let counterClockwiseDegrees =
                        (seconds * -92)
                        .truncatingRemainder(dividingBy: 360)

                    ZStack {
                        backgroundRing(
                            size: side * 1.05,
                            colors: [
                                .cyan.opacity(0.20),
                                .blue.opacity(0.04),
                                .white.opacity(0.18)
                            ]
                        )
                        .rotationEffect(.degrees(clockwiseDegrees))
                        .offset(
                            x: -side * 0.16,
                            y: -side * 0.05
                        )

                        backgroundRing(
                            size: side * 0.86,
                            colors: [
                                .blue.opacity(0.08),
                                .purple.opacity(0.22),
                                .white.opacity(0.12)
                            ]
                        )
                        .rotationEffect(
                            .degrees(counterClockwiseDegrees)
                        )
                        .offset(
                            x: side * 0.16,
                            y: side * 0.02
                        )
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .blendMode(.screen)
                    .opacity(0.72)
                }
            }
        }
    }

    private func backgroundRing(
        size: CGFloat,
        colors: [Color]
    ) -> some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: colors,
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: max(size * 0.055, 12),
                    lineCap: .round,
                    dash: [
                        size * 0.34,
                        size * 0.12,
                        size * 0.08,
                        size * 0.18
                    ]
                )
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    AppBackground()
}
