//
//  MusicConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

struct MusicConfiguration: Decodable {
    let tracks: [MusicTrack]

    static func load(named resourceName: String = "music") throws
        -> MusicConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

struct MusicTrack: Decodable, Identifiable {
    let id: String
    let resourceName: String
    let fileExtension: String
}
