//
//  AppBackground.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RemoteImage(name: "bg_app", contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)

                Color.black.opacity(0.20)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
