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
                AppBackground()

                VStack(spacing: 18) {
                    Spacer()

                    VStack(spacing: 14) {
                        Text("Widerwillen")
                            .widerwillenPixelFont(size: 40, weight: .heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: .black.opacity(0.82),
                                radius: 5,
                                x: 0,
                                y: 3
                            )

                        VStack(spacing: 10) {
                            Image(systemName: statusIconName)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(remoteContentStore.statusText)
                                .widerwillenFont(size: 13, weight: .bold)
                                .foregroundStyle(.white.opacity(0.84))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)
                                .shadow(
                                    color: .black.opacity(0.7),
                                    radius: 3,
                                    x: 0,
                                    y: 2
                                )
                        }
                    }

                    launchProgress
                        .frame(width: min(max(proxy.size.width - 72, 0), 320))
                        .padding(.top, 4)

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 58)
            }
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }

    private var statusIconName: String {
        if remoteContentStore.hasPendingUpdate {
            return "arrow.down.circle.fill"
        }

        if remoteContentStore.isRefreshing {
            return "arrow.triangle.2.circlepath"
        }

        return "sparkles"
    }

    private var launchProgress: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let progress = remoteContentStore.progress ?? 0.12
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.black.opacity(0.48))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                    .stroke(.blue, lineWidth: 1)
            }

            Text(remoteContentStore.progressDetailText)
                .widerwillenFont(size: 11, weight: .bold)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
        }
        .padding(14)
        .background(.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)
    }
}
