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
        try JSONLoader.load(named: "event_shop")
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
