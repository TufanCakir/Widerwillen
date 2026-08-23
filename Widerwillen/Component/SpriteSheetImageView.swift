//
//  SpriteSheetImageView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI
import UIKit

struct SpriteSheetImageView: View {
    let animationID: String
    var contentMode: ContentMode = .fit
    var columns: Int?
    var rows: Int?
    var frameCount: Int?
    var fps: Double?

    @State private var frameIndex = 0
    @State private var frames: [UIImage] = []

    private let animations: [SpriteSheet]

    init(
        animationID: String,
        contentMode: ContentMode = .fit,
        columns: Int? = nil,
        rows: Int? = nil,
        frameCount: Int? = nil,
        fps: Double? = nil
    ) {
        self.animationID = animationID
        self.contentMode = contentMode
        self.columns = columns
        self.rows = rows
        self.frameCount = frameCount
        self.fps = fps
        animations = (try? SpriteSheet.loadAll()) ?? []
    }

    var body: some View {
        Group {
            if let image = currentFrameImage {
                renderedImage(Image(uiImage: image))
            } else if let config {
                RemoteImage(name: config.imageName, contentMode: contentMode)
            } else {
                RemoteImage(name: animationID, contentMode: contentMode)
            }
        }
        .task(id: animationCacheKey) {
            await prepareAndRunAnimation()
        }
    }

    private var config: SpriteSheet? {
        animations.first { $0.id == animationID || $0.imageName == animationID }
    }

    private var resolvedColumns: Int {
        max(columns ?? config?.columns ?? 1, 1)
    }

    private var resolvedRows: Int {
        max(rows ?? config?.rows ?? 1, 1)
    }

    private var resolvedFrameCount: Int {
        max(frameCount ?? config?.frameCount ?? 1, 1)
    }

    private var resolvedFPS: Double {
        max(fps ?? config?.fps ?? 8, 1)
    }

    private var resolvedImageName: String {
        config?.imageName ?? animationID
    }

    private var resolvedSpacing: Int {
        max(config?.spacing ?? 0, 0)
    }

    private var resolvedMargin: Int {
        max(config?.margin ?? 0, 0)
    }

    private var animationCacheKey: String {
        [
            resolvedImageName,
            "\(resolvedColumns)",
            "\(resolvedRows)",
            "\(resolvedSpacing)",
            "\(resolvedMargin)",
            "\(resolvedFrameCount)"
        ].joined(separator: "|")
    }

    private var currentFrameImage: UIImage? {
        guard !frames.isEmpty else { return nil }
        return frames[min(max(frameIndex, 0), frames.count - 1)]
    }

    @MainActor
    private func prepareAndRunAnimation() async {
        frameIndex = 0
        frames = Self.cachedFrames(
            imageName: resolvedImageName,
            columns: resolvedColumns,
            rows: resolvedRows,
            spacing: resolvedSpacing,
            margin: resolvedMargin,
            frameCount: resolvedFrameCount
        )

        await runAnimationLoop(frameCount: frames.count, fps: resolvedFPS)
    }

    @ViewBuilder
    private func renderedImage(_ image: Image) -> some View {
        switch contentMode {
        case .fill:
            image
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        case .fit:
            image
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
        }
    }

    @MainActor
    private func runAnimationLoop(frameCount: Int, fps: Double) async {
        guard frameCount > 1 else { return }

        while !Task.isCancelled {
            let delay = UInt64(1_000_000_000 / max(fps, 1))
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }

            frameIndex = (frameIndex + 1) % frameCount
        }
    }

    private static let frameCache = NSCache<NSString, SpriteFrameCacheEntry>()

    private static func cachedFrames(
        imageName: String,
        columns: Int,
        rows: Int,
        spacing: Int,
        margin: Int,
        frameCount: Int
    ) -> [UIImage] {
        let safeColumns = max(columns, 1)
        let safeRows = max(rows, 1)
        let safeFrameCount = max(min(frameCount, safeColumns * safeRows), 1)
        let cacheKey = [
            imageName,
            "\(safeColumns)",
            "\(safeRows)",
            "\(spacing)",
            "\(margin)",
            "\(safeFrameCount)"
        ].joined(separator: "|") as NSString

        if let cachedEntry = frameCache.object(forKey: cacheKey) {
            return cachedEntry.frames
        }

        guard
            let url = RemoteContentCache.cachedAssetURL(named: imageName),
            let sheet = UIImage(contentsOfFile: url.path)
        else {
            return []
        }

        let generatedFrames = (0..<safeFrameCount).compactMap { index in
            frameImage(
                from: sheet,
                columns: safeColumns,
                rows: safeRows,
                spacing: max(spacing, 0),
                margin: max(margin, 0),
                frameCount: safeFrameCount,
                frameIndex: index
            )
        }

        frameCache.setObject(
            SpriteFrameCacheEntry(frames: generatedFrames),
            forKey: cacheKey
        )
        return generatedFrames
    }

    private static func frameImage(
        from sheet: UIImage,
        columns: Int,
        rows: Int,
        spacing: Int,
        margin: Int,
        frameCount: Int,
        frameIndex: Int
    ) -> UIImage? {
        guard let cgImage = sheet.cgImage,
            columns > 0,
            rows > 0,
            frameCount > 0
        else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let frameWidth =
            (width - margin * 2 - spacing * (columns - 1))
            / columns
        let frameHeight =
            (height - margin * 2 - spacing * (rows - 1))
            / rows

        guard frameWidth > 0, frameHeight > 0 else { return nil }

        let safeIndex = min(
            max(frameIndex, 0),
            min(frameCount, columns * rows) - 1
        )
        let column = safeIndex % columns
        let row = safeIndex / columns
        let rect = CGRect(
            x: margin + column * (frameWidth + spacing),
            y: margin + row * (frameHeight + spacing),
            width: frameWidth,
            height: frameHeight
        )

        guard let croppedImage = cgImage.cropping(to: rect) else {
            return nil
        }

        return UIImage(
            cgImage: croppedImage,
            scale: sheet.scale,
            orientation: sheet.imageOrientation
        )
    }
}

private final class SpriteFrameCacheEntry {
    let frames: [UIImage]

    init(frames: [UIImage]) {
        self.frames = frames
    }
}
