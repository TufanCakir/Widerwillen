//
//  MenuButtonBackground.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 04.09.26.
//

import SwiftUI

struct MenuButtonBackground: View {

    let imageName: String?

    var body: some View {
        Color.black.opacity(0.38)
            .background {
                if let imageName {
                    RemoteImage(
                        name: imageName,
                        contentMode: .fill
                    )
                    .opacity(0.88)
                }
            }
            .clipped()
    }
}
