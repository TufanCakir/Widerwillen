//
//  JSONLoader.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

enum JSONLoader {

    static func load<T: Decodable>(
        _ type: T.Type = T.self,
        named resourceName: String,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        if shouldUseCachedRemoteContent(bundle: bundle),
            let remoteData = RemoteContentCache.cachedJSONData(
                named: resourceName
            ),
            let remoteValue = try? decoder.decode(T.self, from: remoteData)
        {
            return remoteValue
        }

        guard
            let url = bundle.url(
                forResource: resourceName,
                withExtension: "json"
            )
        else {
            throw Error.fileNotFound(resourceName)
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private static func shouldUseCachedRemoteContent(bundle: Bundle) -> Bool {
        let storedRemoteVersion = UserDefaults.standard.integer(
            forKey: "remoteContentVersion"
        )
        guard
            let url = bundle.url(
                forResource: "contentVersion",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let manifest = try? JSONDecoder().decode(
                RemoteContentManifest.self,
                from: data
            )
        else {
            return storedRemoteVersion > 0
        }

        return storedRemoteVersion > manifest.contentVersion
    }
}

extension JSONLoader {
    enum Error: LocalizedError {
        case fileNotFound(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                "JSON file '\(name).json' was not found in the app bundle."
            }
        }
    }
}
