//
//  RemoteImage.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import SwiftUI
import UIKit

struct RemoteImage: View {
    let name: String
    var contentMode: ContentMode = .fit
    var placeholderColor: Color = .black.opacity(0.18)
    var fallbackSystemImage = "photo"

    @AppStorage("remoteContentVersion") private var remoteContentVersion = 0

    var body: some View {
        Group {
            if let image = cachedImage {
                renderedImage(Image(uiImage: image))
            } else {
                fallbackView
            }
        }
        .id("\(name)-\(remoteContentVersion)")
        .onAppear {
            logCacheState()
        }
        .onChange(of: remoteContentVersion) {
            logCacheState()
        }
    }

    private var cachedImage: UIImage? {
        guard let url = RemoteContentCache.cachedAssetURL(named: name) else {
            return nil
        }

        return UIImage(contentsOfFile: url.path)
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

    private var fallbackView: some View {
        fallbackContent
            .frame(
                maxWidth: contentMode == .fill ? .infinity : nil,
                maxHeight: contentMode == .fill ? .infinity : nil
            )
            .clipped()
    }

    private var fallbackContent: some View {
        ZStack {
            placeholderColor

            Image(systemName: systemImageName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.72))
                .padding(8)
        }
    }

    private var systemImageName: String {
        switch name {
        case "bg", "bg_app":
            "square.grid.3x3.fill"
        case _ where name.contains("coin"):
            "circle.fill"
        case _ where name.contains("crystal"):
            "diamond.fill"
        case _ where name.contains("chip"):
            "circle.hexagongrid.fill"
        case _ where name.contains("relic"):
            "hexagon.fill"
        case _ where name.contains("book"):
            "book.fill"
        case _ where name.contains("sword"):
            "bolt.fill"
        case _ where name.contains("box"):
            "shippingbox.fill"
        case _ where name.contains("calendar"):
            "calendar"
        case _ where name.contains("house"):
            "house.fill"
        case _ where name.contains("settings"):
            "gearshape.fill"
        case _ where name.contains("news"):
            "newspaper.fill"
        case _ where name.contains("trade"):
            "arrow.left.arrow.right"
        case _ where name.contains("sprite"):
            "person.crop.square.fill"
        default:
            fallbackSystemImage
        }
    }

    private func logCacheState() {
        if let url = RemoteContentCache.cachedAssetURL(named: name) {
            print("[RemoteImage] cache hit \(name): \(url.path)")
        } else {
            print("[RemoteImage] cache miss \(name). Showing SF Symbol fallback: \(systemImageName)")
        }
    }
}
