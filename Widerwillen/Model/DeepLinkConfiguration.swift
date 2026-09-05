//
//  DeepLinkConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 04.09.26.
//

import Foundation

struct DeepLinkConfiguration: Decodable {
    let scheme: String
    let universalLinkHost: String?
    let links: [DeepLinkDefinition]

    static func load(named resourceName: String = "deeplinks") throws
        -> DeepLinkConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    func resolve(_ url: URL) -> DeepLinkDefinition? {
        let normalizedPath = normalizedPath(for: url)

        return links.first { link in
            link.path == normalizedPath
                || link.aliases.contains(normalizedPath)
                || link.id
                    == normalizedPath.trimmingCharacters(
                        in: CharacterSet(charactersIn: "/")
                    )
        }
    }

    private func normalizedPath(for url: URL) -> String {
        if url.scheme == scheme {
            let hostPart = url.host.map { "/\($0)" } ?? ""
            let path = hostPart + url.path
            return path.isEmpty ? "/" : path
        }

        if let universalLinkHost,
            url.host == universalLinkHost
        {
            return url.path.isEmpty ? "/" : url.path
        }

        return url.path.isEmpty ? "/" : url.path
    }
}

struct DeepLinkDefinition: Decodable, Identifiable {
    let id: String
    let title: String
    let path: String
    let aliases: [String]
    let destination: DeepLinkDestination
    let value: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case path
        case aliases
        case destination
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        path = try container.decode(String.self, forKey: .path)
        aliases =
            try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        destination = try container.decode(
            DeepLinkDestination.self,
            forKey: .destination
        )
        value = try container.decodeIfPresent(String.self, forKey: .value)
    }
}

enum DeepLinkDestination: String, Decodable {
    case home
    case battle
    case showcase
    case event
    case skills
    case settings
    case news
    case gift
    case equipment
    case warehouse
    case pass
    case dailyLogin = "daily_login"
    case backgrounds
    case sprites
    case summon
    case shop
    case trade
}
