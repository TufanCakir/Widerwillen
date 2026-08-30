//
//  AppBackground.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct AppBackground: View {

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.008, green: 0.027, blue: 0.075),  // #020713
                Color(red: 0.027, green: 0.114, blue: 0.227),  // #071D3A
                Color(red: 0.039, green: 0.310, blue: 0.620),  // #0A4F9E
                Color(red: 0.012, green: 0.082, blue: 0.169),  // #03152B
                Color(red: 0.000, green: 0.016, blue: 0.039),  // #00040A
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            LinearGradient(
                colors: [
                    .black.opacity(0.70),
                    .black.opacity(0.08),
                    .black.opacity(0.82),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
