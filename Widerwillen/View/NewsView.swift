//
//  NewsView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct NewsView: View {
    private let configuration: NewsConfiguration

    @State private var selectedCategory = ""

    init(configuration: NewsConfiguration = try! NewsConfiguration.load()) {
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
                    selectedCategory: $selectedCategory
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
            Image(post.imageName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
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

                Text(post.body)
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
