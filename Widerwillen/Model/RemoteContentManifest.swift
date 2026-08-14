//
//  RemoteContentManifest.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct RemoteContentManifest: Decodable {
    let contentVersion: Int
    let json: [RemoteJSONResource]
    let assets: [RemoteFileResource]
    let music: [RemoteFileResource]

    private enum CodingKeys: String, CodingKey {
        case contentVersion
        case json
        case assets
        case music
    }

    init(
        contentVersion: Int,
        json: [RemoteJSONResource] = [],
        assets: [RemoteFileResource] = [],
        music: [RemoteFileResource] = []
    ) {
        self.contentVersion = contentVersion
        self.json = json
        self.assets = assets
        self.music = music
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contentVersion = try container.decodeIfPresent(
            Int.self,
            forKey: .contentVersion
        ) ?? 0
        json = try container.decodeIfPresent(
            [RemoteJSONResource].self,
            forKey: .json
        ) ?? []
        assets = try container.decodeIfPresent(
            [RemoteFileResource].self,
            forKey: .assets
        ) ?? []
        music = try container.decodeIfPresent(
            [RemoteFileResource].self,
            forKey: .music
        ) ?? []
    }
}

struct RemoteJSONResource: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let path: String
}

struct RemoteFileResource: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let path: String
    let version: Int

    private enum CodingKeys: String, CodingKey {
        case name
        case path
        case version
    }

    init(name: String, path: String, version: Int = 1) {
        self.name = name
        self.path = path
        self.version = version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
    }
}
