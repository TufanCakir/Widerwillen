//
//  ContentDateRefresh.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

private struct ContentDateRefresh: ViewModifier {
    @Binding var date: Date
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task(id: scenePhase) {
                date = .now
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: .seconds(1))
                    } catch {
                        return
                    }
                    date = .now
                }
            }
    }
}

extension View {
    func refreshContentDate(_ date: Binding<Date>) -> some View {
        modifier(ContentDateRefresh(date: date))
    }
}
