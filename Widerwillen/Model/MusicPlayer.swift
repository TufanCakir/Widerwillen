//
//  MusicPlayer.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import AVFoundation
import Foundation

final class MusicPlayer: NSObject, AVAudioPlayerDelegate {
    private let configuration: MusicConfiguration
    private var player: AVAudioPlayer?
    private var effectPlayers: [UUID: AVAudioPlayer] = [:]
    private var currentTrackIndex = 0
    private var shouldPlay: Bool
    private var shouldPlaySoundEffects: Bool
    private var musicVolume: Float
    private var soundEffectsVolume: Float

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

    func setEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: "isMusicEnabled")
        shouldPlay = isEnabled

        if isEnabled {
            playCurrentTrack()
        } else {
            player?.stop()
            player = nil
        }
    }

    func resumeIfNeeded() {
        guard shouldPlay else { return }
        guard player?.isPlaying != true else { return }

        playCurrentTrack()
    }

    func setMusicVolume(_ volume: Double) {
        musicVolume = Float(min(max(volume, 0), 1))
        player?.setVolume(musicVolume, fadeDuration: 0.12)
    }

    func setSoundEffectsEnabled(_ isEnabled: Bool) {
        shouldPlaySoundEffects = isEnabled

        if !isEnabled {
            effectPlayers.values.forEach { $0.stop() }
            effectPlayers.removeAll()
        }
    }

    func setSoundEffectsVolume(_ volume: Double) {
        soundEffectsVolume = Float(min(max(volume, 0), 1))
        effectPlayers.values.forEach { $0.volume = soundEffectsVolume }
    }

    func playSoundEffect(_ id: String) {
        guard shouldPlaySoundEffects else { return }
        guard
            let effect = configuration.soundEffects.first(where: { $0.id == id }
            )
        else {
            print("[MusicPlayer] missing sound effect config: \(id)")
            return
        }
        guard let url = url(for: effect) else { return }

        do {
            let effectID = UUID()
            let effectPlayer = try AVAudioPlayer(contentsOf: url)
            effectPlayer.delegate = self
            effectPlayer.numberOfLoops = 0
            effectPlayer.volume =
                soundEffectsVolume * min(max(effect.volume ?? 1, 0), 1)
            effectPlayer.prepareToPlay()
            effectPlayers[effectID] = effectPlayer
            effectPlayer.play()
        } catch {
            print("[MusicPlayer] failed effect \(effect.id): \(error)")
        }
    }

    private func playCurrentTrack(attempts: Int = 0) {
        guard shouldPlay, !configuration.tracks.isEmpty else {
            player?.stop()
            player = nil
            return
        }

        guard attempts < configuration.tracks.count else {
            player = nil
            print("[MusicPlayer] no playable cached music tracks found")
            return
        }

        let normalizedIndex = currentTrackIndex % configuration.tracks.count
        let track = configuration.tracks[normalizedIndex]

        guard let url = url(for: track) else {
            advanceTrackIndex()
            playCurrentTrack(attempts: attempts + 1)
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.numberOfLoops = 0
            player?.volume = musicVolume * min(max(track.volume ?? 1, 0), 1)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print(
                "[MusicPlayer] failed to play \(track.resourceName): \(error)"
            )
            advanceTrackIndex()
            playCurrentTrack(attempts: attempts + 1)
        }
    }

    private func playNextTrack() {
        guard shouldPlay, !configuration.tracks.isEmpty else { return }

        advanceTrackIndex()
        playCurrentTrack()
    }

    private func advanceTrackIndex() {
        currentTrackIndex = (currentTrackIndex + 1) % configuration.tracks.count
    }

    private func url(for track: MusicTrack) -> URL? {
        guard
            let url = RemoteContentCache.cachedMusicURL(
                named: track.resourceName,
                fileExtension: track.fileExtension
            )
        else {
            return nil
        }

        return url
    }

    private func url(for effect: SoundEffect) -> URL? {
        guard
            let url = RemoteContentCache.cachedMusicURL(
                named: effect.resourceName,
                fileExtension: effect.fileExtension
            )
        else {
            return nil
        }

        return url
    }

    func stopAllSoundEffects() {
        effectPlayers.values.forEach { $0.stop() }
        effectPlayers.removeAll()
    }

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        if player === self.player {
            playNextTrack()
        } else {
            effectPlayers = effectPlayers.filter { $0.value !== player }
        }
    }
}
