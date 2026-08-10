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
                Spacer(minLength: 48)

                Image("widerwillen_logo")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 6)

                Spacer(minLength: 44)

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        hasStartedGame = true
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .heavy))
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )

                        Text("Start")
                            .font(.system(size: 30, weight: .heavy))
                            .shadow(
                                color: .black.opacity(0.9),
                                radius: 3,
                                x: 0,
                                y: 0
                            )
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 74)
                    .background {
                        Image("bg")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFill()
                            .opacity(0.78)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.72), lineWidth: 2)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 34)

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
    }
}

#Preview("Start") {
    StartView(hasStartedGame: .constant(false))
}
