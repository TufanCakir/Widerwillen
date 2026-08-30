//
//  EventShopConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 30.08.26.
//

import Foundation

struct EventShopConfiguration: Decodable {

    let shops: [EventShop]

    func shop(for eventID: String) -> EventShop? {
        shops.first { $0.eventID == eventID }
    }

    static func load() throws -> EventShopConfiguration {
        guard
            let url = Bundle.main.url(
                forResource: "event_shop",
                withExtension: "json"
            )
        else {
            throw EventShopError.fileNotFound
        }

        let data = try Data(contentsOf: url)

        return try JSONDecoder().decode(
            EventShopConfiguration.self,
            from: data
        )
    }
}

struct EventShop: Decodable, Identifiable {

    var id: String {
        eventID
    }

    let eventID: String
    let title: String
    let currencyID: String
    let currencyImageName: String
    let offers: [TradeOffer]
}

enum EventShopError: Error {
    case fileNotFound
}
