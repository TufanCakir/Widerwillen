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

    var body: some View {
        ZStack {
            RemoteImage(name: imageName, contentMode: .fill)
                .ignoresSafeArea()

            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                RemoteImage(name: imageName)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.78), lineWidth: 2)
                    }

                Text(areaName)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                ProgressView()
                    .tint(.white)
                    .frame(width: 120)
            }
            .padding(24)
            .background(.black.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .transition(.opacity.combined(with: .scale(scale: 1.05)))
    }
}
