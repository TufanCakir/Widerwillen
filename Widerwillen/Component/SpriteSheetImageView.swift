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
            if let image = frameImage {
                renderedImage(Image(uiImage: image))
            } else if let config {
                RemoteImage(name: config.imageName, contentMode: contentMode)
            } else {
                RemoteImage(name: animationID, contentMode: contentMode)
            }
        }
        .task(id: animationID) {
            await runAnimationLoop()
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

    private var frameImage: UIImage? {
        guard let config,
            let url = RemoteContentCache.cachedAssetURL(named: config.imageName),
            let sheet = UIImage(contentsOfFile: url.path)
        else {
            return nil
        }

        return Self.frameImage(
            from: sheet,
            config: config,
            columns: resolvedColumns,
            rows: resolvedRows,
            frameCount: resolvedFrameCount,
            frameIndex: frameIndex
        )
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

    private func runAnimationLoop() async {
        frameIndex = 0

        guard config != nil, resolvedFrameCount > 1 else { return }

        while !Task.isCancelled {
            let delay = UInt64(1_000_000_000 / resolvedFPS)
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                frameIndex = (frameIndex + 1) % resolvedFrameCount
            }
        }
    }

    private static func frameImage(
        from sheet: UIImage,
        config: SpriteSheet,
        columns: Int,
        rows: Int,
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
        let spacing = max(config.spacing, 0)
        let margin = max(config.margin, 0)
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
