//
//  AvailabilityCountdownView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

/// Compact live countdown shared by every time-limited content card.
struct AvailabilityCountdownView: View {
    let startDate: Date?
    let endDate: Date?
    var emphasized = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            countdown(at: context.date)
                .widerwillenFont(size: emphasized ? 10 : 8, weight: .heavy)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
    }

    @ViewBuilder
    private func countdown(at date: Date) -> some View {
        if let startDate, date < startDate {
            HStack(spacing: 3) {
                Text("Starts in")
                Text(startDate, style: .timer)
            }
            .foregroundStyle(.orange)
        } else if let endDate, date < endDate {
            HStack(spacing: 3) {
                Text("Ends in")
                Text(endDate, style: .timer)
            }
            .foregroundStyle(.white.opacity(emphasized ? 0.9 : 0.48))
        } else if endDate != nil {
            Text("Ended")
                .foregroundStyle(.red.opacity(0.8))
        }
    }
}
