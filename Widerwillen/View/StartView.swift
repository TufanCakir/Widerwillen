//
//  StartView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct StartView: View {
    @Binding var hasStartedGame: Bool

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                RemoteImage(name: "widerwillen_logo")
                    .frame(maxWidth: 200)

                RemoteImage(name: "widerwillen_font_logo")
                    .frame(maxWidth: 280)

                Text("Tap to Start")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                Spacer(minLength: 44)

                Text("Copyright © Tufan Cakir. All rights reserved.")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) {
                hasStartedGame = true
            }
        }
    }
}

#Preview("Start") {
    StartView(hasStartedGame: .constant(false))
}
