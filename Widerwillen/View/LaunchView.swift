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

            VStack(spacing: 20) {
                ZStack {
                    RemoteImage(name: "widerwillen_logo")
                        .frame(width: 190, height: 190)
                        .opacity(0.9)
                        .shadow(
                            color: .black.opacity(0.35),
                            radius: 16,
                            x: 0,
                            y: 8
                        )

                    RemoteImage(name: "widerwillen_font_logo")
                        .frame(maxWidth: 300, maxHeight: 110)
                        .shadow(
                            color: .black.opacity(0.85),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }
                .frame(height: 220)

                VStack(spacing: 10) {
                    if let progress = remoteContentStore.progress {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }

                    Text(remoteContentStore.progressDetailText)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }
                .tint(.white)
                .frame(maxWidth: 260)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.black.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 28)
        }
    }
}
