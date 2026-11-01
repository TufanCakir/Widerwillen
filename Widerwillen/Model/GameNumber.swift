//
//  GameNumber.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

/// Keeps integer-based saves compatible while preventing traps from exponential growth.
enum GameNumber {
    static func integer(_ value: Double) -> Int {
        guard !value.isNaN, value > 0 else { return 0 }
        // Double(Int.max) rounds UP to 2^63 and must never be converted to Int.
        guard value < Double(Int.max) else { return Int.max }
        return Int(value)
    }

    static func adding(_ lhs: Int, _ rhs: Int) -> Int {
        let result = lhs.addingReportingOverflow(rhs)
        return result.overflow
            ? (rhs >= 0 ? Int.max : Int.min) : result.partialValue
    }
}
