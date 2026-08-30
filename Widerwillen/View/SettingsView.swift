import Foundation
import SwiftUI

struct SettingsView: View {
    let progress: GameProgressStore
    var playSoundEffect: (String) -> Void = { _ in }

    @AppStorage("isMusicEnabled") private var isMusicEnabled = true
    @AppStorage("isSoundEffectsEnabled") private var isSoundEffectsEnabled =
        true
    @AppStorage("musicVolume") private var musicVolume = 0.8
    @AppStorage("soundEffectsVolume") private var soundEffectsVolume = 0.9
    @AppStorage("isTutorialEnabled") private var isTutorialEnabled = true
    @AppStorage("remoteContentVersion") private var remoteContentVersion = 0
    @AppStorage("appLanguage") private var appLanguageCode = AppLanguage.de
        .rawValue
    @AppStorage("completedTutorialIDs") private var completedTutorialIDs = ""

    @State private var isResetConfirmationPresented = false
    @State private var resetMessage = ""
    @State private var tutorialMessage = ""

    private let appInfo = AppInfo.current

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    preferencesSection
                    dangerSection
                    appInfoSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .confirmationDialog(
            localizer.text(
                "settings.reset.confirm_title",
                fallback: "Reset game?"
            ),
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(
                localizer.text(
                    "settings.reset.confirm_button",
                    fallback: "Reset Progress"
                ),
                role: .destructive
            ) {
                playSoundEffect("ui_reset")
                resetGame()
            }

            Button(
                localizer.text("common.cancel", fallback: "Cancel"),
                role: .cancel
            ) {
                playSoundEffect("ui_back")
            }
        } message: {
            Text(
                localizer.text(
                    "settings.reset.confirm_message",
                    fallback:
                        "This resets gameplay progress, rewards, currencies and tutorials. Purchases stay available."
                )
            )
        }
    }

    private var localizer: AppLocalizer {
        AppLocalizer(languageCode: appLanguageCode)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localizer.text("settings.title", fallback: "Settings"))
                .widerwillenFont(size: 30, weight: .heavy)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 2)

            Text(
                localizer.text(
                    "settings.subtitle",
                    fallback: "Adjust language, audio and account options."
                )
            )
            .widerwillenFont(size: 13, weight: .bold)
            .foregroundStyle(.white.opacity(0.78))
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
        }
        .padding(.top, 4)
    }

    private var preferencesSection: some View {
        settingsSection(
            title: localizer.text(
                "settings.preferences",
                fallback: "Preferences"
            ),
            systemImage: "slider.horizontal.3"
        ) {
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

            settingsSlider(
                title: localizer.text(
                    "settings.music_volume",
                    fallback: "Music Volume"
                ),
                systemImage: "speaker.wave.2.fill",
                value: $musicVolume,
                isEnabled: isMusicEnabled
            )

            settingsToggle(
                title: localizer.text(
                    "settings.sound_effects",
                    fallback: "Sound Effects"
                ),
                subtitle: isSoundEffectsEnabled
                    ? localizer.text("settings.on", fallback: "On")
                    : localizer.text(
                        "settings.off",
                        fallback: "Off"
                    ),
                systemImage: "speaker.wave.3.fill",
                isOn: $isSoundEffectsEnabled
            )

            settingsSlider(
                title: localizer.text(
                    "settings.sound_effects_volume",
                    fallback: "Sound Effects Volume"
                ),
                systemImage: "waveform",
                value: $soundEffectsVolume,
                isEnabled: isSoundEffectsEnabled
            )

            settingsToggle(
                title: localizer.text(
                    "settings.tutorials",
                    fallback: "Tutorials"
                ),
                subtitle: isTutorialEnabled
                    ? localizer.text("settings.on", fallback: "On")
                    : localizer.text(
                        "settings.off",
                        fallback: "Off"
                    ),
                systemImage: "questionmark.bubble.fill",
                isOn: $isTutorialEnabled
            )

            replayTutorialsButton

            feedbackMessage(tutorialMessage)
        }
    }

    private var dangerSection: some View {
        settingsSection(
            title: localizer.text("settings.account", fallback: "Account"),
            systemImage: "person.crop.circle.badge.exclamationmark"
        ) {
            resetButton
            feedbackMessage(resetMessage)
        }
    }

    private var appInfoSection: some View {
        settingsSection(
            title: localizer.text("settings.about", fallback: "About"),
            systemImage: "info.circle.fill"
        ) {
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

    private func settingsSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .heavy))
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title)
                    .widerwillenFont(size: 16, weight: .heavy)

                Spacer()
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)

            VStack(spacing: 8) {
                content()
            }
        }
    }

    @ViewBuilder
    private func feedbackMessage(_ message: String) -> some View {
        if !message.isEmpty {
            Text(message)
                .widerwillenFont(size: 12, weight: .heavy)
                .foregroundStyle(.white.opacity(0.86))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )
        }
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
                    .widerwillenFont(size: 17, weight: .heavy)
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
        .settingsPanelStyle()
    }

    private func settingsToggle(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .widerwillenFont(size: 14, weight: .bold)

                    Text(subtitle)
                        .widerwillenFont(size: 10, weight: .semibold)
                        .opacity(0.7)
                }
                .foregroundStyle(.white)

                Spacer()

                statusPill(isOn: isOn.wrappedValue)
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 50)
        .settingsPanelStyle()
    }

    private func settingsSlider(
        title: String,
        systemImage: String,
        value: Binding<Double>,
        isEnabled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title)
                    .widerwillenFont(size: 13, weight: .bold)

                Spacer()

                Text("\(Int(value.wrappedValue * 100))%")
                    .widerwillenFont(size: 11, weight: .bold)
                    .opacity(0.8)
            }

            Slider(value: value, in: 0...1)
                .tint(.white)
                .disabled(!isEnabled)
        }
        .foregroundStyle(.white)
        .opacity(isEnabled ? 1 : 0.48)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .settingsPanelStyle()
    }

    private func statusPill(isOn: Bool) -> some View {
        Text(
            isOn
                ? localizer.text("settings.on", fallback: "On")
                : localizer.text("settings.off", fallback: "Off")
        )
        .widerwillenFont(size: 10, weight: .heavy)
        .foregroundStyle(isOn ? .white : .white.opacity(0.62))
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(isOn ? .blue.opacity(0.34) : .black.opacity(0.26))
        .clipShape(Capsule())
    }

    private var replayTutorialsButton: some View {
        Button {
            playSoundEffect("ui_confirm")
            isTutorialEnabled = true
            completedTutorialIDs = ""
            tutorialMessage = localizer.text(
                "settings.tutorials.replay_done",
                fallback: "Tutorials will appear again"
            )

            Task {
                try? await Task.sleep(for: .seconds(1.6))
                await MainActor.run {
                    tutorialMessage = ""
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        localizer.text(
                            "settings.tutorials.replay",
                            fallback: "Show Tutorials Again"
                        )
                    )
                    .widerwillenFont(size: 17, weight: .heavy)

                    Text(
                        localizer.text(
                            "settings.tutorials.replay_subtitle",
                            fallback: "Reset viewed tutorial messages"
                        )
                    )
                    .widerwillenFont(size: 12, weight: .bold)
                    .opacity(0.78)
                }

                Spacer()
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 68)
            .settingsPanelStyle()
        }
        .buttonStyle(.plain)
    }

    private var resetButton: some View {
        Button {
            playSoundEffect("ui_select")
            isResetConfirmationPresented = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        localizer.text(
                            "settings.reset.title",
                            fallback: "Reset Game"
                        )
                    )
                    .widerwillenFont(size: 17, weight: .heavy)

                    Text(
                        localizer.text(
                            "settings.reset.subtitle",
                            fallback: "Start gameplay from the beginning"
                        )
                    )
                    .widerwillenFont(size: 12, weight: .bold)
                    .opacity(0.78)
                }

                Spacer()
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 68)
            .background(.red.opacity(0.62))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func resetGame() {
        progress.resetGameProgress()
        completedTutorialIDs = ""
        resetMessage = localizer.text(
            "settings.reset.done",
            fallback: "Game progress reset"
        )

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                resetMessage = ""
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .widerwillenFont(size: 14, weight: .heavy)
                .foregroundStyle(.white.opacity(0.82))
                .shadow(
                    color: .black.opacity(0.9),
                    radius: 3,
                    x: 0,
                    y: 0
                )

            Spacer(minLength: 12)

            Text(value)
                .widerwillenFont(size: 13, weight: .bold)
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
        .settingsPanelStyle()
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

extension View {
    fileprivate func settingsPanelStyle() -> some View {
        self
            .background(.black.opacity(0.32))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SettingsView(progress: GameProgressStore())
}
