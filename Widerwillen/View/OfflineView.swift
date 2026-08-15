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
            LinearGradient(
                stops: [
                    .init(color: .blue, location: 0),
                    .init(color: .blue, location: 0.5),
                    .init(color: .white, location: 0.5),
                    .init(color: .white, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RemoteImage(name: "widerwillen_logo")
                        .frame(width: 170, height: 170)
                        .opacity(0.76)
                        .shadow(
                            color: .black.opacity(0.38),
                            radius: 16,
                            x: 0,
                            y: 8
                        )

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 58, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }

                VStack(spacing: 8) {
                    Text("No Internet")
                        .font(.system(size: 28, weight: .heavy))

                    Text("Widerwillen needs an internet connection to load game content.")
                        .font(.system(size: 13, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(0.82)

                    Text(connectionName)
                        .font(.system(size: 11, weight: .heavy))
                        .opacity(0.7)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                .padding(.horizontal, 28)
            }
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    OfflineView(connectionName: "Offline")
}
