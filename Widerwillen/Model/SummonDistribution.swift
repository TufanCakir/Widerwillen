//
//  SummonDistribution.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

/// One source of truth for the displayed rates and the actual draw.
struct SummonDistribution {
    struct Outcome: Identifiable {
        let entry: SummonEntry
        let probability: Double
        var id: String { entry.id }
    }

    let outcomes: [Outcome]

    init(entries: [SummonEntry]) {
        let largestWeight =
            entries.map { $0.weight.isFinite ? max($0.weight, 0) : 0 }.max()
            ?? 0
        // Scale before summing so even extremely large valid weights cannot overflow.
        let weights = entries.map {
            largestWeight > 0 && $0.weight.isFinite
                ? max($0.weight, 0) / largestWeight : 0
        }
        let total = weights.reduce(0, +)
        outcomes = zip(entries, weights).map { entry, weight in
            Outcome(entry: entry, probability: total > 0 ? weight / total : 0)
        }
    }

    var canDraw: Bool { outcomes.contains { $0.probability > 0 } }

    func draw(unitRoll: Double = Double.random(in: 0..<1)) -> SummonEntry? {
        guard canDraw, unitRoll.isFinite, (0..<1).contains(unitRoll) else {
            return nil
        }
        var remaining = unitRoll
        for outcome in outcomes where outcome.probability > 0 {
            if remaining < outcome.probability { return outcome.entry }
            remaining -= outcome.probability
        }
        return outcomes.last { $0.probability > 0 }?.entry
    }
}
