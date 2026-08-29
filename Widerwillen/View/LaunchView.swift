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
            AppBackground()

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            Text("Widerwillen")
                .widerwillenFont(size: 34, weight: .heavy)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 5, x: 0, y: 2)
        }
        .transition(.opacity)
    }
}
