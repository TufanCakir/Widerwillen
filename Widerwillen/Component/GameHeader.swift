//
//  GameHeader.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SwiftUI

struct GameHeader: View {
    let progress: GameProgressStore

    private let iconConfiguration: ProfileIconConfiguration

    @State private var isShowingProfilePicker = false

    init(
        progress: GameProgressStore,
        iconConfiguration: ProfileIconConfiguration =
            try! ProfileIconConfiguration.load()
    ) {
        self.progress = progress
        self.iconConfiguration = iconConfiguration
    }

    var body: some View {
        headerContent
            .padding(.horizontal)
            .fullScreenCover(isPresented: $isShowingProfilePicker) {
                profilePickerScreen
            }
    }

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                profileIconButton

                Text("LV \(progress.accountLevel)")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.black.opacity(0.28))

                        Capsule()
                            .fill(.white.opacity(0.48))
                            .frame(
                                width: proxy.size.width
                                    * min(max(progress.accountXPProgress, 0), 1)
                            )
                    }
                }
                .frame(width: 110, height: 8)
            }

            Spacer()

            AppResourceLabel(
                imageName: "icon_pixel_coin",
                value: progress.coins,
                iconSize: 24,
                fontSize: 13
            )

            AppResourceLabel(
                imageName: "icon_pixel_crystal",
                value: progress.crystals,
                iconSize: 24,
                fontSize: 13
            )

            AppResourceLabel(
                imageName: "icon_pixel_relic",
                value: progress.artifactShards,
                iconSize: 22,
                fontSize: 12
            )

            AppResourceLabel(
                imageName: "icon_pixel_skill_book",
                value: progress.skillBooks,
                iconSize: 22,
                fontSize: 12
            )
        }
    }

    private var profileIconButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                isShowingProfilePicker.toggle()
            }
        } label: {
            profileIconImage(progress.selectedProfileIconImageName, size: 52)
                .background(.black.opacity(0.32))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.78), lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var profilePickerScreen: some View {
        GeometryReader { proxy in
            ZStack {
                AppBackground()

                profilePickerPanel(
                    width: min(proxy.size.width - 28, 316),
                    maxHeight: proxy.size.height * 0.74
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func profilePickerPanel(width: CGFloat, maxHeight: CGFloat)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Profile Icon")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )

                Spacer()

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isShowingProfilePicker = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: pickerColumns, spacing: 8) {
                    ForEach(iconConfiguration.icons) { icon in
                        iconChoice(icon)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .frame(width: width)
        .frame(maxHeight: maxHeight)
        .background(.black.opacity(0.76))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.62), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 6)
    }

    private var pickerColumns: [GridItem] {
        [
            GridItem(.fixed(58), spacing: 8),
            GridItem(.fixed(58), spacing: 8),
            GridItem(.fixed(58), spacing: 8),
            GridItem(.fixed(58), spacing: 8),
        ]
    }

    private func iconChoice(_ icon: ProfileIcon) -> some View {
        let isSelected = progress.selectedProfileIconImageName == icon.imageName

        return Button {
            progress.selectProfileIcon(icon)
            withAnimation(.snappy(duration: 0.2)) {
                isShowingProfilePicker = false
            }
        } label: {
            VStack(spacing: 6) {
                profileIconImage(icon.imageName, size: 34)

                Text(icon.title)
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 0
                    )
            }
            .frame(width: 58, height: 58)
            .background(.white.opacity(isSelected ? 0.2 : 0.08))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? .white.opacity(0.92) : .white.opacity(0.28),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func profileIconImage(_ imageName: String, size: CGFloat)
        -> some View
    {
        RemoteImage(name: imageName)
            .padding(6)
            .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GameHeader(
            progress: GameProgressStore()
        )
    }
}
