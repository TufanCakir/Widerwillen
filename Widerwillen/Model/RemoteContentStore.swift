//
//  RemoteContentStore.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation
import Observation

@Observable
@MainActor
final class RemoteContentStore {
    private static let baseURL = URL(
        string: "https://remotewiderwillen.tufancakir.com/"
    )!
    private static let manifestPath = "contentVersion.json"
    private static let versionKey = "remoteContentVersion"

    private let session: URLSession
    private let decoder = JSONDecoder()

    private(set) var isRefreshing = false
    private(set) var progress: Double?
    private(set) var statusText = "Bundle content"
    private(set) var contentVersion = UserDefaults.standard.integer(
        forKey: versionKey
    )

    init() {
        let cache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 120 * 1024 * 1024,
            diskPath: "WiderwillenRemoteURLCache"
        )
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 20
        session = URLSession(configuration: configuration)
    }

    func refreshIfNeeded() async {
        guard !isRefreshing else {
            remoteLog("Refresh skipped because another refresh is running")
            return
        }

        isRefreshing = true
        progress = nil
        statusText = "Checking content"
        remoteLog("Refresh started. Stored version: \(contentVersion)")
        defer {
            isRefreshing = false
            progress = nil
        }

        do {
            let manifest = try await fetchManifest()
            let missingResources = RemoteContentCache.missingResourceNames(
                in: manifest
            )
            let shouldUpdateVersion = manifest.contentVersion > contentVersion
            let shouldRepairCache = !missingResources.isEmpty

            remoteLog(
                """
                Manifest version: \(manifest.contentVersion). JSON: \(manifest.json.count), assets: \(manifest.assets.count), music: \(manifest.music.count). Missing cache files: \(missingResources.count)
                """
            )

            guard shouldUpdateVersion || shouldRepairCache else {
                statusText = "Content up to date"
                remoteLog("Refresh finished. Content is up to date.")
                return
            }

            try RemoteContentCache.prepareDirectories()
            let summary = await downloadResources(
                from: manifest,
                onlyMissing: !shouldUpdateVersion
            )

            guard summary.succeededCount > 0 || summary.failedResources.isEmpty
            else {
                statusText = contentVersion > 0 ? "Cached content" : "Bundle content"
                remoteLog(
                    "Refresh stopped. No resources could be downloaded. Failed: \(summary.failedResources.joined(separator: ", "))"
                )
                return
            }

            contentVersion = manifest.contentVersion
            UserDefaults.standard.set(
                manifest.contentVersion,
                forKey: Self.versionKey
            )
            statusText = summary.failedResources.isEmpty
                ? "Content updated"
                : "Content updated with missing files"
            remoteLog(
                "Refresh finished. Stored version is now \(contentVersion). Succeeded: \(summary.succeededCount), failed: \(summary.failedResources.count)"
            )
        } catch {
            remoteLog("Remote manifest failed: \(error)")
            do {
                guard let fallbackManifest = bundledManifest() else {
                    statusText = contentVersion > 0
                        ? "Cached content"
                        : "Bundle content"
                    remoteLog("No bundled contentVersion.json fallback found.")
                    return
                }

                statusText = "Repairing cached content"
                try RemoteContentCache.prepareDirectories()
                let summary = await downloadResources(
                    from: fallbackManifest,
                    onlyMissing: true
                )
                statusText = contentVersion > 0
                    ? "Cached content"
                    : "Bundle content"
                remoteLog(
                    "Cache repair from bundled manifest finished. Succeeded: \(summary.succeededCount), failed: \(summary.failedResources.count)"
                )
            } catch {
                statusText = contentVersion > 0 ? "Cached content" : "Bundle content"
                remoteLog("Cache repair from bundled manifest failed: \(error)")
            }
        }
    }

    private func fetchManifest() async throws -> RemoteContentManifest {
        let url = Self.baseURL.appending(path: Self.manifestPath)
        remoteLog("Fetching manifest: \(url.absoluteString)")
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadRevalidatingCacheData,
            timeoutInterval: 8
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        remoteLog("Manifest response bytes: \(data.count)")
        return try decoder.decode(RemoteContentManifest.self, from: data)
    }

    private func downloadResources(
        from manifest: RemoteContentManifest,
        onlyMissing: Bool
    )
        async -> DownloadSummary
    {
        let totalCount =
            manifest.json.count + manifest.assets.count + manifest.music.count
        guard totalCount > 0 else {
            remoteLog("Manifest has no resources to download.")
            return DownloadSummary()
        }

        remoteLog(
            "Downloading resources. Total: \(totalCount), onlyMissing: \(onlyMissing)"
        )

        var summary = DownloadSummary()
        var completedCount = 0

        for resource in manifest.json {
            if onlyMissing,
                RemoteContentCache.hasCachedJSON(named: resource.name)
            {
                summary.succeededCount += 1
                completedCount += 1
                progress = Double(completedCount) / Double(totalCount)
                remoteLog("JSON cache hit, skipped: \(resource.name)")
                continue
            }

            let url = Self.baseURL.appending(path: resource.path)
            remoteLog("Downloading JSON \(resource.name): \(url.absoluteString)")
            var request = URLRequest(
                url: url,
                cachePolicy: .reloadRevalidatingCacheData,
                timeoutInterval: 8
            )
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await session.data(for: request)
                try validate(response: response)
                try RemoteContentCache.storeJSON(data, named: resource.name)
                summary.succeededCount += 1
                remoteLog("Stored JSON \(resource.name). Bytes: \(data.count)")
            } catch {
                summary.failedResources.append("json:\(resource.name)")
                remoteLog("Failed JSON \(resource.name): \(error)")
            }

            completedCount += 1
            progress = Double(completedCount) / Double(totalCount)
        }

        for resource in manifest.assets {
            await downloadFile(
                resource,
                kind: .asset,
                onlyMissing: onlyMissing,
                summary: &summary,
                completedCount: &completedCount,
                totalCount: totalCount
            )
        }

        for resource in manifest.music {
            await downloadFile(
                resource,
                kind: .music,
                onlyMissing: onlyMissing,
                summary: &summary,
                completedCount: &completedCount,
                totalCount: totalCount
            )
        }

        if !summary.failedResources.isEmpty {
            remoteLog(
                "Resource download warnings: \(summary.failedResources.joined(separator: ", "))"
            )
        }

        return summary
    }

    private func downloadFile(
        _ resource: RemoteFileResource,
        kind: RemoteContentCache.FileKind,
        onlyMissing: Bool,
        summary: inout DownloadSummary,
        completedCount: inout Int,
        totalCount: Int
    ) async {
        if RemoteContentCache.hasCachedFile(resource, kind: kind) {
            summary.succeededCount += 1
            completedCount += 1
            progress = Double(completedCount) / Double(totalCount)
            remoteLog(
                "\(kind.logName) cache hit, skipped: \(resource.name) v\(resource.version). onlyMissing: \(onlyMissing)"
            )
            return
        }

        let url = Self.baseURL.appending(path: resource.path)
        remoteLog(
            "Downloading \(kind.logName) \(resource.name): \(url.absoluteString)"
        )
        let request = URLRequest(
            url: url,
            cachePolicy: .reloadRevalidatingCacheData,
            timeoutInterval: 12
        )

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response)
            try RemoteContentCache.storeFile(data, resource: resource, kind: kind)
            summary.succeededCount += 1
            remoteLog(
                "Stored \(kind.logName) \(resource.name) v\(resource.version). Bytes: \(data.count)"
            )
        } catch {
            summary.failedResources.append("\(kind.logName):\(resource.name)")
            remoteLog("Failed \(kind.logName) \(resource.name): \(error)")
        }

        completedCount += 1
        progress = Double(completedCount) / Double(totalCount)
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        remoteLog(
            "HTTP \(httpResponse.statusCode): \(httpResponse.url?.absoluteString ?? "unknown url")"
        )
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func bundledManifest() -> RemoteContentManifest? {
        guard let url = Bundle.main.url(
            forResource: "contentVersion",
            withExtension: "json"
        ) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let manifest = try decoder.decode(
                RemoteContentManifest.self,
                from: data
            )
            remoteLog(
                "Loaded bundled contentVersion.json fallback. Version: \(manifest.contentVersion)"
            )
            return manifest
        } catch {
            remoteLog("Bundled contentVersion.json decode failed: \(error)")
            return nil
        }
    }

    private func remoteLog(_ message: String) {
        print("[RemoteContent] \(message)")
    }

    private struct DownloadSummary {
        var succeededCount = 0
        var failedResources: [String] = []
    }
}

enum RemoteContentCache {
    private static let jsonDirectoryName = "RemoteJSON"
    private static let assetDirectoryName = "RemoteAssets"
    private static let musicDirectoryName = "RemoteMusic"

    enum FileKind {
        case asset
        case music

        var logName: String {
            switch self {
            case .asset:
                "asset"
            case .music:
                "music"
            }
        }
    }

    static func cachedJSONData(named resourceName: String) -> Data? {
        try? Data(contentsOf: jsonURL(named: resourceName))
    }

    static func cachedAssetURL(named resourceName: String) -> URL? {
        cachedFileURL(named: resourceName, kind: .asset)
    }

    static func cachedMusicURL(named resourceName: String) -> URL? {
        cachedFileURL(named: resourceName, kind: .music)
    }

    static func hasCachedJSON(named resourceName: String) -> Bool {
        FileManager.default.fileExists(atPath: jsonURL(named: resourceName).path)
    }

    static func hasCachedFile(
        _ resource: RemoteFileResource,
        kind: FileKind
    ) -> Bool {
        FileManager.default.fileExists(
            atPath: fileURL(
                named: resource.name,
                version: resource.version,
                kind: kind
            ).path
        )
    }

    static func missingResourceNames(in manifest: RemoteContentManifest)
        -> [String]
    {
        let missingJSON = manifest.json
            .filter { !hasCachedJSON(named: $0.name) }
            .map { "json:\($0.name)" }
        let missingAssets = manifest.assets
            .filter { !hasCachedFile($0, kind: .asset) }
            .map { "asset:\($0.name):v\($0.version)" }
        let missingMusic = manifest.music
            .filter { !hasCachedFile($0, kind: .music) }
            .map { "music:\($0.name):v\($0.version)" }

        return missingJSON + missingAssets + missingMusic
    }

    static func storeJSON(_ data: Data, named resourceName: String) throws {
        try prepareDirectories()
        try data.write(to: jsonURL(named: resourceName), options: .atomic)
    }

    static func storeFile(
        _ data: Data,
        resource: RemoteFileResource,
        kind: FileKind
    ) throws {
        try prepareDirectories()
        try removeOldVersionedFiles(
            named: resource.name,
            keepingVersion: resource.version,
            kind: kind
        )
        try data.write(
            to: fileURL(
                named: resource.name,
                version: resource.version,
                kind: kind
            ),
            options: .atomic
        )
    }

    static func prepareDirectories() throws {
        for directory in [jsonDirectory, assetDirectory, musicDirectory] {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
    }

    private static func jsonURL(named resourceName: String) -> URL {
        jsonDirectory.appending(path: "\(resourceName).json")
    }

    private static func cachedFileURL(
        named resourceName: String,
        kind: FileKind
    ) -> URL? {
        if let latestVersionedURL = cachedVersionedFileURLs(
            named: resourceName,
            kind: kind
        )
        .sorted(by: { versionNumber(from: $0) < versionNumber(from: $1) })
        .last {
            return latestVersionedURL
        }

        let legacyURL = fileURL(named: resourceName, kind: kind)
        return FileManager.default.fileExists(atPath: legacyURL.path)
            ? legacyURL
            : nil
    }

    private static func fileURL(named resourceName: String, kind: FileKind)
        -> URL
    {
        legacyFileURL(named: resourceName, kind: kind)
    }

    private static func fileURL(
        named resourceName: String,
        version: Int,
        kind: FileKind
    ) -> URL {
        directory(for: kind).appending(
            path:
                "\(resourceName)_v\(max(version, 1)).\(fileExtension(for: kind))"
        )
    }

    private static func legacyFileURL(named resourceName: String, kind: FileKind)
        -> URL
    {
        directory(for: kind).appending(
            path: "\(resourceName).\(fileExtension(for: kind))"
        )
    }

    private static func cachedVersionedFileURLs(
        named resourceName: String,
        kind: FileKind
    ) -> [URL] {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: directory(for: kind),
                includingPropertiesForKeys: nil
            )
        else {
            return []
        }

        let prefix = "\(resourceName)_v"
        let suffix = ".\(fileExtension(for: kind))"

        return urls.filter {
            $0.lastPathComponent.hasPrefix(prefix)
                && $0.lastPathComponent.hasSuffix(suffix)
        }
    }

    private static func removeOldVersionedFiles(
        named resourceName: String,
        keepingVersion version: Int,
        kind: FileKind
    ) throws {
        let keepURL = fileURL(named: resourceName, version: version, kind: kind)

        for url in cachedVersionedFileURLs(named: resourceName, kind: kind)
        where url != keepURL {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func versionNumber(from url: URL) -> Int {
        let name = url.deletingPathExtension().lastPathComponent
        guard let markerRange = name.range(of: "_v", options: .backwards)
        else {
            return 0
        }

        return Int(name[markerRange.upperBound...]) ?? 0
    }

    private static func directory(for kind: FileKind) -> URL {
        switch kind {
        case .asset:
            assetDirectory
        case .music:
            musicDirectory
        }
    }

    private static func fileExtension(for kind: FileKind) -> String {
        switch kind {
        case .asset:
            "png"
        case .music:
            "mp3"
        }
    }

    private static var jsonDirectory: URL {
        applicationSupportDirectory.appending(path: jsonDirectoryName)
    }

    private static var assetDirectory: URL {
        applicationSupportDirectory.appending(path: assetDirectoryName)
    }

    private static var musicDirectory: URL {
        applicationSupportDirectory.appending(path: musicDirectoryName)
    }

    private static var applicationSupportDirectory: URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return baseURL.appending(path: "Widerwillen")
    }
}
