//
//  CategoryBar.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct CategoryBar: View {
    let categories: [String]
    @Binding var selectedCategory: String
    var playSoundEffect: (String) -> Void = { _ in }
    var displayName: (String) -> String = { $0 }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            if selectedCategory == category {
                                playSoundEffect("ui_tap")
                            }
                            selectedCategory = category
                            scrollToCategory(category, proxy: proxy)
                        } label: {
                            Text(displayName(category))
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )
                                .lineLimit(1)
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background {
                                    Capsule()
                                        .fill(
                                            selectedCategory == category
                                                ? .white.opacity(0.24)
                                                : .black.opacity(0.28)
                                        )
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(0.7), lineWidth: 1)
                                }
                                .shadow(
                                    color: .black.opacity(0.9),
                                    radius: 3,
                                    x: 0,
                                    y: 2
                                )
                        }
                        .buttonStyle(.plain)
                        .id(category)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                scrollToCategory(selectedCategory, proxy: proxy, animated: false)
            }
            .onChange(of: selectedCategory) { _, newCategory in
                playSoundEffect("ui_page")
                scrollToCategory(newCategory, proxy: proxy)
            }
        }
    }

    private func scrollToCategory(
        _ category: String,
        proxy: ScrollViewProxy,
        animated: Bool = true
    ) {
        guard categories.contains(category) else { return }

        if animated {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(category, anchor: .center)
            }
        } else {
            proxy.scrollTo(category, anchor: .center)
        }
    }
}

struct ResourceAmountRow: View {
    let amounts: [TradeResourceAmount]
    var prefix = ""
    var color: Color = .white

    var body: some View {
        HStack(spacing: 8) {
            ForEach(amounts) { amount in
                AppResourceLabel(
                    imageName: amount.imageName ?? amount.resource.imageName,
                    value: amount.amount,
                    prefix: prefix,
                    iconSize: 20,
                    fontSize: 12,
                    color: color
                )
            }
        }
    }
}
