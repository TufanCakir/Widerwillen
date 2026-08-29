//
//  WiderwillenApp.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

@main
struct WiderwillenApp: App {
    init() {
        WiderwillenTypography.registerFontIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
