//
//  ProfileIconConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct ProfileIconConfiguration: Decodable {
    let icons: [ProfileIcon]

    static func load(named resourceName: String = "icon") throws
        -> ProfileIconConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct ProfileIcon: Decodable, Identifiable {
    let id: String
    let title: String
    let imageName: String
    let requiredAccountLevel: Int?
}
