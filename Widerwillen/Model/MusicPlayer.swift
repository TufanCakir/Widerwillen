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
    private var currentTrackIndex = 0
    private var shouldPlay = false

    init(
        configuration: MusicConfiguration = (try? MusicConfiguration.load())
            ?? MusicConfiguration(tracks: [])
    ) {
        self.configuration = configuration
        super.init()
    }

    func setEnabled(_ isEnabled: Bool) {
        shouldPlay = isEnabled
        print("[MusicPlayer] music enabled: \(isEnabled)")

        if isEnabled {
            playCurrentTrack()
        } else {
            player?.stop()
            player = nil
            print("[MusicPlayer] stopped")
        }
    }

    private func playCurrentTrack(attempts: Int = 0) {
        guard shouldPlay, !configuration.tracks.isEmpty else {
            print(
                "[MusicPlayer] play skipped. shouldPlay: \(shouldPlay), tracks: \(configuration.tracks.count)"
            )
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
            player?.prepareToPlay()
            player?.play()
            print(
                "[MusicPlayer] playing \(track.resourceName): \(url.path)"
            )
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
        guard let url = RemoteContentCache.cachedMusicURL(
            named: track.resourceName
        ) else {
            print("[MusicPlayer] cache miss \(track.resourceName)")
            return nil
        }

        print("[MusicPlayer] cache hit \(track.resourceName): \(url.path)")
        return url
    }

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        playNextTrack()
    }
}
