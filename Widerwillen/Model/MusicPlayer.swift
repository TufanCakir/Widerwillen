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

        if isEnabled {
            playCurrentTrack()
        } else {
            player?.stop()
            player = nil
        }
    }

    private func playCurrentTrack(attempts: Int = 0) {
        guard shouldPlay, !configuration.tracks.isEmpty else { return }
        guard attempts < configuration.tracks.count else {
            player = nil
            return
        }

        let normalizedIndex = currentTrackIndex % configuration.tracks.count
        let track = configuration.tracks[normalizedIndex]

        guard
            let url = Bundle.main.url(
                forResource: track.resourceName,
                withExtension: track.fileExtension
            )
        else {
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
        } catch {
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

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        playNextTrack()
    }
}
