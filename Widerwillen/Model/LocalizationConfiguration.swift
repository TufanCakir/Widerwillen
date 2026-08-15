//
//  LocalizationConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import Foundation

struct LocalizationConfiguration: Decodable {
    let strings: [String: String]

    static func load(named resourceName: String) throws
        -> LocalizationConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case de
    case en

    var id: String { rawValue }

    var title: String {
        switch self {
        case .de:
            "Deutsch"
        case .en:
            "English"
        }
    }
}

struct AppLocalizer {
    let language: AppLanguage

    private let configuration: LocalizationConfiguration

    init(languageCode: String) {
        let language = AppLanguage(rawValue: languageCode) ?? .de
        self.language = language
        configuration =
            (try? LocalizationConfiguration.load(named: language.rawValue))
            ?? LocalizationConfiguration(strings: [:])
    }

    func text(_ key: String?, fallback: String) -> String {
        guard let key, !key.isEmpty else { return fallback }
        return configuration.strings[key] ?? fallback
    }

    func text(_ key: String, fallback: String) -> String {
        configuration.strings[key] ?? fallback
    }
}
