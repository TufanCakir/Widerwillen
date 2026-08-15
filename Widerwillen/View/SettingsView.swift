import Foundation
import SwiftUI

struct SettingsView: View {
    @AppStorage("isMusicEnabled") private var isMusicEnabled = true
    @AppStorage("isLayerAnimationEnabled") private var isLayerAnimationEnabled =
        true
    @AppStorage("remoteContentVersion") private var remoteContentVersion = 0
    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue

    private let appInfo = AppInfo.current

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    sectionTitle(
                        localizer.text("settings.title", fallback: "Settings")
                    )

                    VStack(spacing: 10) {
                        languagePicker

                        settingsToggle(
                            title: localizer.text(
                                "settings.music",
                                fallback: "Music"
                            ),
                            subtitle: isMusicEnabled
                                ? localizer.text("settings.on", fallback: "On")
                                : localizer.text(
                                    "settings.off",
                                    fallback: "Off"
                                ),
                            systemImage: "music.note",
                            isOn: $isMusicEnabled
                        )
                        settingsToggle(
                            title: localizer.text(
                                "settings.layer_animation",
                                fallback: "Layer Animation"
                            ),
                            subtitle: isLayerAnimationEnabled
                                ? localizer.text("settings.on", fallback: "On")
                                : localizer.text(
                                    "settings.off",
                                    fallback: "Off"
                                ),
                            systemImage: "sparkles",
                            isOn: $isLayerAnimationEnabled
                        )
                    }

                    sectionTitle(
                        localizer.text("settings.info", fallback: "Info")
                    )

                    VStack(spacing: 10) {
                        infoRow(title: "App", value: appInfo.name)
                        infoRow(title: "Version", value: appInfo.version)
                        infoRow(title: "Build", value: appInfo.build)
                        infoRow(
                            title: localizer.text(
                                "settings.content",
                                fallback: "Content"
                            ),
                            value: contentVersionTitle
                        )
                        infoRow(
                            title: "Bundle",
                            value: appInfo.bundleIdentifier
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 110)
            }
        }
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: "globe")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(localizer.text("settings.language", fallback: "Language"))
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

                Spacer()
            }

            Picker(
                localizer.text("settings.language", fallback: "Language"),
                selection: $appLanguageCode
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title)
                        .tag(language.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            RemoteImage(name: "bg_app", contentMode: .fill)
                .opacity(0.72)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 24, weight: .heavy))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
    }

    private func settingsToggle(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    )
        -> some View
    {
        Toggle(isOn: isOn) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.78)
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }
                .foregroundStyle(.white)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 2
                )
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 68)
        .background {
            RemoteImage(name: "bg_app", contentMode: .fill)
                .opacity(0.72)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white.opacity(0.82))
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )
        }
        .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .background {
            RemoteImage(name: "bg_app", contentMode: .fill)
                .opacity(0.56)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var contentVersionTitle: String {
        remoteContentVersion > 0
            ? "Remote v\(remoteContentVersion)"
            : localizer.text("settings.bundle", fallback: "Bundle")
    }
}

private struct AppInfo {
    let name: String
    let version: String
    let build: String
    let bundleIdentifier: String

    static var current: AppInfo {
        let bundle = Bundle.main

        return AppInfo(
            name: bundle.string(for: "CFBundleDisplayName")
                ?? bundle.string(for: "CFBundleName")
                ?? "Widerwillen",
            version: bundle.string(for: "CFBundleShortVersionString") ?? "1.0",
            build: bundle.string(for: "CFBundleVersion") ?? "1",
            bundleIdentifier: bundle.bundleIdentifier ?? "-"
        )
    }
}

extension Bundle {
    fileprivate func string(for key: String) -> String? {
        object(forInfoDictionaryKey: key) as? String
    }
}

#Preview {
    SettingsView()
}
