//
//  ContentSchedule.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

/// Shared availability state for time-limited content such as events and summon banners.
enum ContentAvailability: Equatable {
    case upcoming
    case active
    case ended
}

struct ContentSchedule: Equatable {
    let startDate: Date?
    let endDate: Date?

    func availability(at date: Date = .now) -> ContentAvailability {
        if let startDate, date < startDate {
            return .upcoming
        }

        if let endDate, date >= endDate {
            return .ended
        }

        return .active
    }

    func isActive(at date: Date = .now) -> Bool {
        availability(at: date) == .active
    }
}

enum GermanDateParser {
    static func parse(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.isLenient = false
        return formatter.date(from: value)
    }
}
