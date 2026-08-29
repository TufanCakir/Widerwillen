//
//  LaunchView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import SwiftUI

struct LaunchView: View {
    let remoteContentStore: RemoteContentStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                launchBackground

                VStack(spacing: 18) {
                    Spacer()

                    VStack(spacing: 10) {
                        Text("Widerwillen")
                            .widerwillenFont(size: 36, weight: .heavy)
                            .foregroundStyle(.white)
                            .shadow(
                                color: .black.opacity(0.82),
                                radius: 5,
                                x: 0,
                                y: 3
                            )

                        Text(remoteContentStore.statusText)
                            .widerwillenFont(size: 13, weight: .bold)
                            .foregroundStyle(.white.opacity(0.82))
                            .shadow(
                                color: .black.opacity(0.7),
                                radius: 3,
                                x: 0,
                                y: 2
                            )
                    }

                    launchProgress
                        .frame(width: min(proxy.size.width - 72, 320))

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 58)
            }
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }

    private var launchBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.31, blue: 0.70),
                    Color(red: 0.03, green: 0.50, blue: 0.92),
                    Color(red: 0.86, green: 0.02, blue: 0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                let tileSize = max(proxy.size.width / 5.6, 54)
                let columns = Int(proxy.size.width / tileSize) + 2
                let rows = Int(proxy.size.height / tileSize) + 2

                Canvas { context, size in
                    for row in 0..<rows {
                        for column in 0..<columns {
                            let x = CGFloat(column) * tileSize - tileSize * 0.5
                            let y = CGFloat(row) * tileSize - tileSize * 0.35
                            let rect = CGRect(
                                x: x,
                                y: y,
                                width: tileSize * 0.62,
                                height: tileSize * 0.62
                            )
                            let path = Path(
                                roundedRect: rect,
                                cornerRadius: min(tileSize * 0.08, 8)
                            )
                            context.fill(
                                path,
                                with: .color(.white.opacity(0.13))
                            )
                        }
                    }

                    let overlay = Path(CGRect(origin: .zero, size: size))
                    context.fill(
                        overlay,
                        with: .color(.black.opacity(0.18))
                    )
                }
            }
        }
    }

    private var launchProgress: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let progress = remoteContentStore.progress ?? 0.12
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.black.opacity(0.38))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.88))
                        .frame(
                            width: max(
                                18,
                                proxy.size.width * min(max(progress, 0), 1)
                            )
                        )
                }
            }
            .frame(height: 8)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }

            Text(remoteContentStore.progressDetailText)
                .widerwillenFont(size: 11, weight: .bold)
                .foregroundStyle(.white.opacity(0.78))
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
        }
    }
}
