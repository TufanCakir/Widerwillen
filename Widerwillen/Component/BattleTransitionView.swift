//
//  BattleTransitionView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI

struct BattleTransitionView: View {
    let areaName: String
    let imageName: String

    @State private var isFlying = false

    var body: some View {
        GeometryReader { proxy in
            let iconSize = min(max(proxy.size.width * 0.24, 84), 132)
            let travelDistance = proxy.size.height + iconSize * 2

            ZStack {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()

                flyingBackgroundIcon(
                    size: iconSize,
                    xOffset: -proxy.size.width * 0.18,
                    delay: 0,
                    travelDistance: travelDistance
                )

                flyingBackgroundIcon(
                    size: iconSize * 0.78,
                    xOffset: proxy.size.width * 0.16,
                    delay: 0.22,
                    travelDistance: travelDistance
                )
                .opacity(0.78)

                Text(areaName)
                    .widerwillenFont(size: 26, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
                    .frame(maxWidth: proxy.size.width - 48)
                    .position(
                        x: proxy.size.width * 0.5,
                        y: proxy.size.height * 0.5
                    )
            }
            .onAppear {
                isFlying = false
                withAnimation(.easeInOut(duration: 0.95)) {
                    isFlying = true
                }
            }
        }
        .transition(.opacity)
    }

    private func flyingBackgroundIcon(
        size: CGFloat,
        xOffset: CGFloat,
        delay: Double,
        travelDistance: CGFloat
    ) -> some View {
        RemoteImage(name: imageName, contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.82), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.75), radius: 8, x: 0, y: 5)
            .offset(
                x: xOffset,
                y: isFlying ? -travelDistance * 0.52 : travelDistance * 0.52
            )
            .animation(
                .easeInOut(duration: 0.95).delay(delay),
                value: isFlying
            )
    }
}
