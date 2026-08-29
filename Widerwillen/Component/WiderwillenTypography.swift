//
//  WiderwillenTypography.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import CoreText
import SwiftUI

enum WiderwillenTypography {
    static let fontName = "WiderwillenPixel-Regular"
    private static let fileName = "WiderwillenPixel_Regular_v0.2_A-Z"

    static func registerFontIfNeeded() {
        let urls = [
            Bundle.main.url(forResource: fileName, withExtension: "ttf"),
            Bundle.main.url(
                forResource: fileName,
                withExtension: "ttf",
                subdirectory: "Font"
            ),
        ].compactMap { $0 }

        guard let url = urls.first else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

extension Font {
    static func widerwillenPixel(size: CGFloat) -> Font {
        .custom(WiderwillenTypography.fontName, size: size)
    }
}

extension View {
    func widerwillenFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self
            .font(.system(size: size, weight: weight))
    }

    func widerwillenPixelFont(
        size: CGFloat,
        weight: Font.Weight = .regular
    ) -> some View {
        self
            .font(.widerwillenPixel(size: size))
            .fontWeight(weight)
            .textCase(.uppercase)
    }

    func widerwillenTypography() -> some View {
        self.font(.system(size: 14))
    }
}
