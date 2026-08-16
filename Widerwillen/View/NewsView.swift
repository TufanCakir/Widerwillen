//
//  NewsView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct NewsView: View {
    let playSoundEffect: (String) -> Void

    private let configuration: NewsConfiguration

    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @State private var selectedCategory = ""

    init(
        playSoundEffect: @escaping (String) -> Void = { _ in },
        configuration: NewsConfiguration = try! NewsConfiguration.load()
    ) {
        self.playSoundEffect = playSoundEffect
        self.configuration = configuration
        _selectedCategory = State(
            initialValue: configuration.news.first?.category ?? ""
        )
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                CategoryBar(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    playSoundEffect: playSoundEffect,
                    displayName: localizedCategory
                )

                TabView(selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        newsPage(for: category)
                            .tag(category)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private var categories: [String] {
        var values: [String] = []

        for post in configuration.news where !values.contains(post.category) {
            values.append(post.category)
        }

        return values
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private func localizedCategory(_ category: String) -> String {
        let key = configuration.news.first { $0.category == category }?
            .categoryKey
        return localizer.text(key, fallback: category)
    }

    private func localizedTitle(_ post: NewsPost) -> String {
        localizer.text(post.titleKey, fallback: post.title)
    }

    private func localizedBody(_ post: NewsPost) -> String {
        localizer.text(post.bodyKey, fallback: post.body)
    }

    private func newsPage(for category: String) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(configuration.news.filter { $0.category == category }) {
                    post in
                    newsCard(post)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 110)
        }
    }

    private func newsCard(_ post: NewsPost) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImage(name: post.imageName)
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 8) {
                Text(localizedTitle(post))
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                Text(post.date)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.68))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                Text(localizedBody(post))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )
            }

            Spacer()
        }
        .padding(14)
        .background(.black.opacity(0.24))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    NewsView()
}
