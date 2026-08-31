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

            VStack(spacing: 24) {
                VStack(spacing: 18) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 50, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 92)
                        .background(.black.opacity(0.34))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.blue, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                .padding(22)
                .frame(maxWidth: 340)
                .background(.black.opacity(0.42))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
