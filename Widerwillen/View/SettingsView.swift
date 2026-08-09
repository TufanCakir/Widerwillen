//
//  SettingsView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isLayerAnimationEnabled") private var isLayerAnimationEnabled =
        true

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {

                Toggle(isOn: $isLayerAnimationEnabled) {
                    Text("Layer Animation")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 24)
                .frame(height: 58)
                .background {
                    Image("bg")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                        .opacity(0.72)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SettingsView()
}
