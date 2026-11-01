//
//  JSONContentGroup.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import Foundation

enum JSONContentGroup: String {
    case events = "event"
    case summons = "summon"

    func contains(_ name: String) -> Bool {
        // event_shop belongs to a different schema.
        name == rawValue
            || (name.hasPrefix(rawValue + "_") && name != "event_shop")
    }
}

extension JSONLoader {
    /// Each file keeps its existing wrapper, e.g. { "events": [...] }.
    /// New bundled files need target membership; remote files need a manifest entry.
    static func loadCollection<Configuration: Decodable, Entry: Identifiable>(
        _ type: Configuration.Type,
        group: JSONContentGroup,
        entries keyPath: KeyPath<Configuration, [Entry]>,
        bundle: Bundle = .main
    ) throws -> [Entry] where Entry.ID == String {
        let urls =
            bundle.urls(forResourcesWithExtension: "json", subdirectory: nil)
            ?? []
        let bundledNames = Set(
            urls.map { $0.deletingPathExtension().lastPathComponent }
                .filter { group.contains($0) }
        )
        var names = bundledNames

        if shouldUseCachedRemoteContent(bundle: bundle) {
            let remoteNames = Set(
                RemoteContentCache.activeJSONResourceNames.filter {
                    group.contains($0)
                }
            )
            if !remoteNames.isEmpty,
                remoteNames.allSatisfy({
                    RemoteContentCache.hasCachedJSON(named: $0)
                })
            {
                if remoteNames == [group.rawValue] {
                    // Legacy servers only know the original file. Keep monthly files
                    // bundled with newer app versions during the format migration.
                    names.formUnion(remoteNames)
                } else {
                    // Only an explicitly modular remote group replaces all bundle files.
                    names = remoteNames
                }
            } else if RemoteContentCache.activeJSONResourceNames.isEmpty,
                RemoteContentCache.hasCachedJSON(named: group.rawValue)
            {
                // Compatibility with caches created before the resource index existed.
                names.insert(group.rawValue)
            }
        }

        var result: [Entry] = []
        var seen: Set<String> = []
        for name in names.sorted() {
            do {
                let configuration: Configuration = try load(
                    type,
                    named: name,
                    bundle: bundle
                )
                for entry in configuration[keyPath: keyPath] {
                    guard seen.insert(entry.id).inserted else {
                        print(
                            "[JSONLoader] Duplicate ID '\(entry.id)' in \(name).json; keeping first entry."
                        )
                        continue
                    }
                    result.append(entry)
                }
            } catch {
                // One invalid optional content file must not take down the whole game.
                print("[JSONLoader] Skipping \(name).json: \(error)")
            }
        }
        return result
    }
}
