//
//  MusicPlayer.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import AVFoundation
import Foundation

final class MusicPlayer: NSObject, AVAudioPlayerDelegate {

    // MARK: - Configuration

    private let configuration: MusicConfiguration

    // MARK: - Players

    private var player: AVAudioPlayer?
    private var effectPlayers: [UUID: AVAudioPlayer] = [:]

    private var currentTrackIndex = 0

    // MARK: - Settings

    private var shouldPlay: Bool
    private var shouldPlaySoundEffects: Bool

    private var musicVolume: Float
    private var soundEffectsVolume: Float

    // MARK: - Audio Session

    private let audioSession = AVAudioSession.sharedInstance()

    /// Eigene Queue für AVAudioSession-Arbeit.
    /// Dadurch blockieren setCategory / Aktivierung nicht die UI.
    private let audioSessionQueue = DispatchQueue(
        label: "com.tufancakir.widerwillen.audio-session",
        qos: .userInitiated
    )

    private var isAudioSessionActive = false
    private var isAudioSessionActivating = false

    private var pendingAudioActions: [() -> Void] = []

    // MARK: - Init

    init(
        configuration: MusicConfiguration = (try? MusicConfiguration.load())
            ?? MusicConfiguration(tracks: [])
    ) {

        self.configuration = configuration

        let defaults = UserDefaults.standard

        shouldPlay =
            defaults.object(forKey: "isMusicEnabled") == nil
            ? true
            : defaults.bool(forKey: "isMusicEnabled")

        shouldPlaySoundEffects =
            defaults.object(forKey: "isSoundEffectsEnabled") == nil
            ? true
            : defaults.bool(forKey: "isSoundEffectsEnabled")

        musicVolume =
            defaults.object(forKey: "musicVolume") == nil
            ? 0.8
            : Float(defaults.double(forKey: "musicVolume"))

        soundEffectsVolume =
            defaults.object(forKey: "soundEffectsVolume") == nil
            ? 0.9
            : Float(defaults.double(forKey: "soundEffectsVolume"))

        super.init()
    }

    // MARK: - Music Settings

    func setEnabled(_ isEnabled: Bool) {

        UserDefaults.standard.set(
            isEnabled,
            forKey: "isMusicEnabled"
        )

        shouldPlay = isEnabled

        if isEnabled {
            playCurrentTrack()
        } else {
            player?.stop()
            player = nil
        }
    }

    func resumeIfNeeded() {

        guard shouldPlay else {
            return
        }

        guard player?.isPlaying != true else {
            return
        }

        playCurrentTrack()
    }

    func setMusicVolume(_ volume: Double) {

        musicVolume = Float(
            min(max(volume, 0), 1)
        )

        player?.setVolume(
            musicVolume,
            fadeDuration: 0.12
        )
    }

    // MARK: - Sound Effect Settings

    func setSoundEffectsEnabled(_ isEnabled: Bool) {

        shouldPlaySoundEffects = isEnabled

        UserDefaults.standard.set(
            isEnabled,
            forKey: "isSoundEffectsEnabled"
        )

        if !isEnabled {
            stopAllSoundEffects()
        }
    }

    func setSoundEffectsVolume(_ volume: Double) {

        soundEffectsVolume = Float(
            min(max(volume, 0), 1)
        )

        effectPlayers.values.forEach {
            $0.volume = soundEffectsVolume
        }
    }

    // MARK: - Sound Effects

    func playSoundEffect(_ id: String) {

        guard shouldPlaySoundEffects else {
            return
        }

        guard
            let effect = configuration.soundEffects.first(
                where: { $0.id == id }
            )
        else {

            print(
                "[MusicPlayer] Missing sound effect config: \(id)"
            )

            return
        }

        guard let url = url(for: effect) else {
            return
        }

        performWhenAudioSessionActive { [weak self] in

            guard let self else {
                return
            }

            do {

                let effectID = UUID()

                let effectPlayer = try AVAudioPlayer(
                    contentsOf: url
                )

                effectPlayer.delegate = self
                effectPlayer.numberOfLoops = 0

                let configuredVolume = min(
                    max(effect.volume ?? 1, 0),
                    1
                )

                effectPlayer.volume =
                    self.soundEffectsVolume * configuredVolume

                effectPlayer.prepareToPlay()

                self.effectPlayers[effectID] = effectPlayer

                effectPlayer.play()

            } catch {

                print(
                    "[MusicPlayer] Failed effect \(effect.id): \(error)"
                )
            }
        }
    }

    // MARK: - Music Playback

    private func playCurrentTrack(
        attempts: Int = 0
    ) {

        guard shouldPlay,
            !configuration.tracks.isEmpty
        else {

            player?.stop()
            player = nil

            return
        }

        performWhenAudioSessionActive { [weak self] in

            guard let self else {
                return
            }

            self.startCurrentTrack(
                attempts: attempts
            )
        }
    }

    private func startCurrentTrack(
        attempts: Int
    ) {

        guard shouldPlay else {
            return
        }

        guard attempts < configuration.tracks.count else {

            player = nil

            print(
                "[MusicPlayer] No playable cached music tracks found"
            )

            return
        }

        let normalizedIndex =
            currentTrackIndex % configuration.tracks.count

        let track =
            configuration.tracks[normalizedIndex]

        guard let url = url(for: track) else {

            advanceTrackIndex()

            startCurrentTrack(
                attempts: attempts + 1
            )

            return
        }

        do {

            let newPlayer = try AVAudioPlayer(
                contentsOf: url
            )

            newPlayer.delegate = self
            newPlayer.numberOfLoops = 0

            let configuredVolume = min(
                max(track.volume ?? 1, 0),
                1
            )

            newPlayer.volume =
                musicVolume * configuredVolume

            newPlayer.prepareToPlay()

            player = newPlayer

            newPlayer.play()

        } catch {

            print(
                "[MusicPlayer] Failed to play \(track.resourceName): \(error)"
            )

            advanceTrackIndex()

            startCurrentTrack(
                attempts: attempts + 1
            )
        }
    }

    private func playNextTrack() {

        guard shouldPlay,
            !configuration.tracks.isEmpty
        else {
            return
        }

        advanceTrackIndex()

        playCurrentTrack()
    }

    private func advanceTrackIndex() {

        guard !configuration.tracks.isEmpty else {
            return
        }

        currentTrackIndex =
            (currentTrackIndex + 1)
            % configuration.tracks.count
    }

    // MARK: - Audio Session

    private func performWhenAudioSessionActive(
        _ action: @escaping () -> Void
    ) {
        // Alle Statusänderungen passieren auf dem Main Thread.
        if isAudioSessionActive {
            action()
            return
        }

        pendingAudioActions.append(action)

        guard !isAudioSessionActivating else {
            return
        }

        isAudioSessionActivating = true

        // AVAudioSession kann blockieren.
        // Deshalb konfigurieren + aktivieren wir sie auf einer eigenen Queue.
        audioSessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            do {
                try self.audioSession.setCategory(
                    .soloAmbient,
                    mode: .default
                )

                // iOS 17 kompatibel.
                // Wichtig: NICHT auf dem Main Thread.
                try self.audioSession.setActive(true)

                DispatchQueue.main.async {
                    self.isAudioSessionActivating = false
                    self.isAudioSessionActive = true

                    let actions = self.pendingAudioActions
                    self.pendingAudioActions.removeAll()

                    actions.forEach { $0() }
                }

            } catch {
                DispatchQueue.main.async {
                    self.isAudioSessionActivating = false
                    self.isAudioSessionActive = false
                    self.pendingAudioActions.removeAll()

                    print(
                        "[MusicPlayer] Failed to activate audio session: \(error)"
                    )
                }

                return
            }
        }
    }

    // MARK: - URLs

    private func url(
        for track: MusicTrack
    ) -> URL? {

        RemoteContentCache.cachedMusicURL(
            named: track.resourceName,
            fileExtension: track.fileExtension
        )
    }

    private func url(
        for effect: SoundEffect
    ) -> URL? {

        RemoteContentCache.cachedMusicURL(
            named: effect.resourceName,
            fileExtension: effect.fileExtension
        )
    }

    // MARK: - Stop

    func stopAllSoundEffects() {

        effectPlayers.values.forEach {
            $0.stop()
        }

        effectPlayers.removeAll()
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {

        if player === self.player {

            playNextTrack()

        } else {

            effectPlayers =
                effectPlayers.filter {
                    $0.value !== player
                }
        }
    }
}
