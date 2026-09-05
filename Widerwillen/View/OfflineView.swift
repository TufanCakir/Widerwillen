//
//  OfflineView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import SwiftUI

struct OfflineView: View {
    let connectionName: String

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 50, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 92)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )

                    VStack(spacing: 9) {
                        Text("No Internet")
                            .widerwillenFont(size: 28, weight: .heavy)

                        Text(
                            "Widerwillen needs an internet connection to load game content."
                        )
                        .widerwillenFont(size: 13, weight: .bold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .opacity(0.82)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 12, weight: .heavy))

                        Text(connectionName)
                            .widerwillenFont(size: 11, weight: .heavy)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                .padding(22)
                .frame(maxWidth: 340)
                .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)

                Text("Reconnect to continue")
                    .widerwillenFont(size: 12, weight: .heavy)
                    .foregroundStyle(.white.opacity(0.72))
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            }
            .padding(.horizontal, 28)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OfflineView(connectionName: "Offline")
}
