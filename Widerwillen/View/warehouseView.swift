//
//  warehouseView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct warehouseView: View {
    let progress: GameProgressStore

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                GameHeader(progress: progress)

                Spacer()

                VStack(spacing: 0) {

                    HStack(spacing: 10) {
                        AppResourceLabel(
                            imageName: "icon_pixel_coin",
                            value: progress.pendingCoins,
                            prefix: "+",
                            iconSize: 28,
                            fontSize: 15
                        )

                        AppResourceLabel(
                            imageName: "icon_pixel_crystal",
                            value: progress.pendingCrystals,
                            prefix: "+",
                            iconSize: 28,
                            fontSize: 15
                        )
                    }

                    Button {
                        progress.claimIdleRewards()
                    } label: {
                        Image("icon_pixel_box")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                            .opacity(progress.hasPendingRewards ? 1 : 0.45)
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 2
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!progress.hasPendingRewards)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .onAppear {
                progress.refreshIdleRewards()
            }
        }
    }
}

#Preview {
    warehouseView(progress: GameProgressStore())
}
