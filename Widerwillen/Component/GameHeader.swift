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

    private var resourceColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
        ]
    }

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 12) {

            // MARK: - Profil
            profileIconButton

            // MARK: - Level / Titel / XP
            VStack(alignment: .center, spacing: 5) {

                Text(selectedProfileTitle?.title ?? "Neuling")
                    .widerwillenFont(size: 10, weight: .heavy)
                    .foregroundStyle(.cyan.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("LV \(progress.accountLevel)")
                    .widerwillenFont(size: 18, weight: .heavy)
                    .foregroundStyle(.white)
                    .shadow(
                        color: .black.opacity(0.9),
                        radius: 3,
                        x: 0,
                        y: 2
                    )

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(.black.opacity(0.28))

                        Capsule()
                            .fill(.white.opacity(0.48))
                            .frame(
                                width: proxy.size.width
                                    * min(
                                        max(progress.accountXPProgress, 0),
                                        1
                                    )
                            )
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)

            // MARK: - Ressourcen 2 × 2
            LazyVGrid(
                columns: resourceColumns,
                alignment: .leading,
                spacing: 6
            ) {

                AppResourceLabel(
                    imageName: "icon_pixel_coin",
                    value: Double(progress.coins),
                    iconSize: 22,
                    fontSize: 11
                )

                AppResourceLabel(
                    imageName: "icon_pixel_crystal",
                    value: Double(progress.crystals),
                    iconSize: 22,
                    fontSize: 11
                )

                AppResourceLabel(
                    imageName: "icon_pixel_relic",
                    value: Double(progress.artifactShards),
                    iconSize: 20,
                    fontSize: 10
                )

                AppResourceLabel(
                    imageName: "icon_pixel_skill_book",
                    value: Double(progress.skillBooks),
                    iconSize: 20,
                    fontSize: 10
                )
            }
            .frame(width: 130)
        }
    }

    private var profileIconButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                isShowingProfilePicker.toggle()
            }
        } label: {
            profileIconImage(
                progress.selectedProfileIconImageName,
                size: 52
            )
            .background {
                AppBackground()
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(
                color: .black.opacity(0.9),
                radius: 3,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    private var profilePickerScreen: some View {
        GeometryReader { proxy in
            ZStack {
                AppBackground()

                profilePickerPanel(
                    width: min(max(proxy.size.width - 28, 0), 316),
                    maxHeight: max(proxy.size.height * 0.74, 0)
                )
            }
            .frame(
                width: max(proxy.size.width, 0),
                height: max(proxy.size.height, 0)
            )
        }
    }

    private func profilePickerPanel(width: CGFloat, maxHeight: CGFloat)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Profil")
                    .widerwillenFont(size: 15, weight: .heavy)
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

            titlePicker

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
        .background {
            AppBackground()
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue, lineWidth: 1)
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
        let isUnlocked =
            progress.accountLevel >= (icon.requiredAccountLevel ?? 1)

        return Button {
            progress.selectProfileIcon(icon)
            withAnimation(.snappy(duration: 0.2)) {
                isShowingProfilePicker = false
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    profileIconImage(icon.imageName, size: 34)
                        .saturation(isUnlocked ? 1 : 0)
                        .opacity(isUnlocked ? 1 : 0.45)

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }

                Text(icon.title)
                    .widerwillenFont(size: 8, weight: .heavy)
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
            .background {
                AppBackground()
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? .blue.opacity(0.95)
                            : .blue.opacity(0.28),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    private var selectedProfileTitle: ProfileTitle? {
        iconConfiguration.titles.first {
            $0.id == progress.selectedProfileTitleID
        }
    }

    private var titlePicker: some View {
        Menu {
            ForEach(iconConfiguration.titles) { title in
                let isUnlocked =
                    progress.accountLevel >= title.requiredAccountLevel
                Button {
                    progress.selectProfileTitle(title)
                } label: {
                    Label(
                        isUnlocked
                            ? title.title
                            : "\(title.title) · LV \(title.requiredAccountLevel)",
                        systemImage: isUnlocked ? "checkmark.seal" : "lock.fill"
                    )
                }
                .disabled(!isUnlocked)
            }
        } label: {
            HStack(spacing: 8) {
                Text("Titel")
                    .foregroundStyle(.white.opacity(0.62))
                Spacer()
                Text(selectedProfileTitle?.title ?? "Neuling")
                    .foregroundStyle(.cyan)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .widerwillenFont(size: 11, weight: .heavy)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(.black.opacity(0.24))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.cyan.opacity(0.45), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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
