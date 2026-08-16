//
//  ChipConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 16.08.26.
//

import Foundation

struct ChipConfiguration: Decodable {
    let chips: [EventChip]

    static func load(named resourceName: String = "chip") throws
        -> ChipConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    func chip(id: String?) -> EventChip? {
        guard let id else { return nil }
        return chips.first { $0.id == id }
    }
}

struct EventChip: Decodable, Identifiable {
    let id: String
    let name: String
    let nameKey: String?
    let imageName: String
}
