//
//  TutorialCoachView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import SwiftUI

struct TutorialCoachView: View {
    let progress: GameProgressStore
    let trigger: TutorialTrigger

    private let configuration: TutorialConfiguration

    @AppStorage("completedTutorialIDs") private var completedTutorialIDs = ""
    @State private var activeTutorial: TutorialDefinition?
    @State private var messageIndex = 0

    init(
        progress: GameProgressStore,
        trigger: TutorialTrigger,
        configuration: TutorialConfiguration =
            (try? TutorialConfiguration.load())
            ?? TutorialConfiguration(tutorials: [])
    ) {
        self.progress = progress
        self.trigger = trigger
        self.configuration = configuration
    }

    var body: some View {
        Group {
            if let activeTutorial {
                coachOverlay(activeTutorial)
            }
        }
        .onAppear {
            updateActiveTutorial()
        }
        .onChange(of: progress.accountLevel) { _, _ in
            updateActiveTutorial()
        }
        .onChange(of: trigger) { _, _ in
            updateActiveTutorial()
        }
    }

    private func coachOverlay(_ tutorial: TutorialDefinition) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.24)
                .ignoresSafeArea()

            HStack(alignment: .bottom, spacing: 12) {
                RemoteImage(name: tutorial.speakerImageName)
                    .frame(width: 86, height: 86)
                    .shadow(color: .black.opacity(0.9), radius: 5, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tutorial.speakerName)
                                .font(.system(size: 12, weight: .heavy))
                                .opacity(0.78)

                            Text(tutorial.title)
                                .font(.system(size: 18, weight: .heavy))
                        }

                        Spacer()

                        Button {
                            complete(tutorial)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .heavy))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(currentMessage(for: tutorial))
                        .font(.system(size: 13, weight: .bold))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        advance(tutorial)
                    } label: {
                        Text(isLastMessage(for: tutorial) ? "OK" : "Next")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(.white.opacity(0.18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.62), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 0)
                .padding(14)
                .background(.black.opacity(0.78))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.62), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .zIndex(50)
    }

    private func currentMessage(for tutorial: TutorialDefinition) -> String {
        guard !tutorial.messages.isEmpty else { return "" }
        return tutorial.messages[min(messageIndex, tutorial.messages.count - 1)]
    }

    private func isLastMessage(for tutorial: TutorialDefinition) -> Bool {
        messageIndex >= tutorial.messages.count - 1
    }

    private func advance(_ tutorial: TutorialDefinition) {
        if isLastMessage(for: tutorial) {
            complete(tutorial)
        } else {
            withAnimation(.snappy(duration: 0.18)) {
                messageIndex += 1
            }
        }
    }

    private func complete(_ tutorial: TutorialDefinition) {
        var ids = completedIDs
        ids.insert(tutorial.id)
        completedTutorialIDs = ids.sorted().joined(separator: ",")

        withAnimation(.snappy(duration: 0.2)) {
            activeTutorial = nil
            messageIndex = 0
        }
    }

    private func updateActiveTutorial() {
        guard activeTutorial == nil else { return }

        let nextTutorial = configuration.tutorials.first {
            $0.trigger == trigger
                && progress.accountLevel >= $0.requiredAccountLevel
                && !completedIDs.contains($0.id)
        }

        guard let nextTutorial else { return }

        messageIndex = 0
        withAnimation(.snappy(duration: 0.24)) {
            activeTutorial = nextTutorial
        }
    }

    private var completedIDs: Set<String> {
        Set(
            completedTutorialIDs
                .split(separator: ",")
                .map(String.init)
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        TutorialCoachView(progress: GameProgressStore(), trigger: .launch)
    }
}
