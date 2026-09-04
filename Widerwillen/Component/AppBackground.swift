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

    private let configuration =
        (try? MenuBackgroundConfiguration.load())
        ?? MenuBackgroundConfiguration.fallback

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.008, green: 0.027, blue: 0.075),  // #020713
                    Color(red: 0.027, green: 0.114, blue: 0.227),  // #071D3A
                    Color(red: 0.039, green: 0.310, blue: 0.620),  // #0A4F9E
                    Color(red: 0.012, green: 0.082, blue: 0.169),  // #03152B
                    Color(red: 0.000, green: 0.016, blue: 0.039),  // #00040A
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let imageName = selectedBackground.imageName {
                RemoteImage(name: imageName, contentMode: .fill)
                    .opacity(0.86)
            }

            if selectedBackground.usesAnimatedRings {
                rotatingBackgroundRings
            }

            LinearGradient(
                colors: [
                    .black.opacity(0.70),
                    .black.opacity(0.08),
                    .black.opacity(
                        min(0.96, 0.82 + selectedBackground.darkening)
                    ),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var selectedBackground: MenuBackgroundDefinition {
        configuration.backgrounds.first { $0.id == selectedMenuBackgroundID }
            ?? configuration.backgrounds.first
            ?? MenuBackgroundConfiguration.fallback.backgrounds[0]
    }

    private var rotatingBackgroundRings: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let isScreenSized =
                proxy.size.width >= 320 && proxy.size.height >= 520

            if side > 220 && isScreenSized {
                TimelineView(.animation) { timeline in
                    let seconds = timeline.date.timeIntervalSinceReferenceDate
                    let clockwise = Angle.degrees(seconds * 5)
                    let counterClockwise = Angle.degrees(seconds * -3.8)

                    ZStack {
                        backgroundRing(
                            size: side * 1.05,
                            colors: [
                                .cyan.opacity(0.20),
                                .blue.opacity(0.04),
                                .white.opacity(0.18),
                            ]
                        )
                        .rotationEffect(clockwise)
                        .offset(x: -side * 0.16, y: -side * 0.05)

                        backgroundRing(
                            size: side * 0.86,
                            colors: [
                                .blue.opacity(0.08),
                                .purple.opacity(0.22),
                                .white.opacity(0.12),
                            ]
                        )
                        .rotationEffect(counterClockwise)
                        .offset(x: side * 0.16, y: side * 0.02)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blendMode(.screen)
                    .opacity(0.72)
                }
            }
        }
        .allowsHitTesting(false)
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
                    dash: [size * 0.34, size * 0.12, size * 0.08, size * 0.18]
                )
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    AppBackground()
}
