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

    private let localizedBundle: Bundle
    private let legacyConfiguration: LocalizationConfiguration

    init(languageCode: String) {
        let language = AppLanguage(rawValue: languageCode) ?? .de
        self.language = language
        localizedBundle = Bundle.main.localizedBundle(for: language)
        legacyConfiguration =
            (try? LocalizationConfiguration.load(named: language.rawValue))
            ?? LocalizationConfiguration(strings: [:])
    }

    func text(_ key: String?, fallback: String) -> String {
        guard let key, !key.isEmpty else { return fallback }
        return text(key, fallback: fallback)
    }

    func text(_ key: String, fallback: String) -> String {
        let legacyFallback = legacyConfiguration.strings[key] ?? fallback
        return localizedBundle.localizedString(
            forKey: key,
            value: legacyFallback,
            table: nil
        )
    }
}

extension Bundle {
    fileprivate func localizedBundle(for language: AppLanguage) -> Bundle {
        guard
            let path = path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return self
        }

        return bundle
    }
}
