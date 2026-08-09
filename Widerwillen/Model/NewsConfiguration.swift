//
//  NewsConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct NewsConfiguration: Decodable {
    let news: [NewsPost]

    static func load(named resourceName: String = "news") throws
        -> NewsConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct NewsPost: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
    let imageName: String
    let date: String
    let body: String
}
