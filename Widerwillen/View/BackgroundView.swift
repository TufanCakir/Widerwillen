//
//  BackgroundView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 04.09.26.
//

import SwiftUI

struct BackgroundView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                sectionTitle("Backgrounds", systemImage: "photo.fill")

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(progress.availableMenuBackgrounds) { background in
                        backgroundTile(background)
                    }
                }

                sectionTitle("Menu Buttons", systemImage: "circle.grid.2x2.fill")

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(progress.availableMenuButtonLooks) { look in
                        buttonLookTile(look)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .background(.black.opacity(0.18))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Style")
                .widerwillenFont(size: 28, weight: .heavy)
                .foregroundStyle(.white)

            Text("Tap to equip")
                .widerwillenFont(size: 12, weight: .bold)
                .foregroundStyle(.white.opacity(0.68))
        }
        .shadow(color: .black.opacity(0.9), radius: 3, y: 2)
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .heavy))
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .widerwillenFont(size: 16, weight: .heavy)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.9), radius: 3)
    }

    private func backgroundTile(
        _ background: MenuBackgroundDefinition
    ) -> some View {
        let isSelected = progress.selectedMenuBackgroundID == background.id

        return Button {
            playSoundEffect("ui_select")
            progress.selectMenuBackground(background)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.black.opacity(0.32))

                    if let imageName = background.imageName {
                        RemoteImage(name: imageName, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "circle.dashed.inset.filled")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .aspectRatio(1.35, contentMode: .fit)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                                ? Color.cyan.opacity(0.92)
                                : Color.white.opacity(0.14),
                            lineWidth: isSelected ? 2 : 1
                        )
                }

                Text(background.title)
                    .widerwillenFont(size: 11, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .padding(10)
            .background(.black.opacity(isSelected ? 0.42 : 0.24))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func buttonLookTile(_ look: MenuButtonLookDefinition) -> some View {
        let isSelected = progress.selectedMenuButtonLookID == look.id

        return Button {
            playSoundEffect("ui_select")
            progress.selectMenuButtonLook(look)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.38))
                        .frame(width: 70, height: 70)

                    if let imageName = look.imageName {
                        RemoteImage(name: imageName, contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .stroke(.blue.opacity(0.72), lineWidth: 2)
                            .frame(width: 54, height: 54)
                    }
                }
                .overlay {
                    Circle()
                        .stroke(
                            isSelected
                                ? Color.cyan.opacity(0.92)
                                : Color.white.opacity(0.14),
                            lineWidth: isSelected ? 2 : 1
                        )
                }

                Text(look.title)
                    .widerwillenFont(size: 11, weight: .heavy)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(.black.opacity(isSelected ? 0.42 : 0.24))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BackgroundView(progress: GameProgressStore(), playSoundEffect: { _ in })
}
