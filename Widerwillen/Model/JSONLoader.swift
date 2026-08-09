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
