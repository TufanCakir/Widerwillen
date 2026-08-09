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

                Image("widerwillen_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)

                Text("Tap to Start")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hasStartedGame = true
        }
    }
}

#Preview("Start") {
    StartView(hasStartedGame: .constant(false))
}
