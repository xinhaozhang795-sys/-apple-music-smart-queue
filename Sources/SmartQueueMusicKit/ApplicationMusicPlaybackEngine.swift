import Foundation
import MusicKit
import SmartQueueCore

/// MusicKit-backed playback adapter for the app's private ApplicationMusicPlayer.
@available(iOS 18.0, *)
public final class ApplicationMusicPlaybackEngine: @unchecked Sendable, PlaybackEngine, PlaybackTransitionControlling {
    private let player: ApplicationMusicPlayer

    public init(player: ApplicationMusicPlayer = .shared) {
        self.player = player
    }

    public var capabilities: PlaybackCapabilities {
        PlaybackCapabilities(
            canSeek: true,
            canPreloadNext: false,
            canCrossfade: true
        )
    }

    public var state: PlaybackState {
        let currentID = player.queue.currentEntry?.id
        let playbackTime = player.playbackTime
        let position = playbackTime.isFinite ? playbackTime : 0
        return PlaybackState(
            trackID: currentID,
            position: position,
            duration: nil,
            isPlaying: player.state.playbackStatus == .playing
        )
    }

    public func play() async throws {
        try await player.play()
    }

    public func pause() async throws {
        player.pause()
    }

    public func skipNext() async throws {
        try await player.skipToNextEntry()
    }

    public func skipPrevious() async throws {
        try await player.skipToPreviousEntry()
    }

    public func seek(to position: TimeInterval) async throws {
        guard position.isFinite else { return }
        player.playbackTime = max(0, position)
    }

    public func apply(transition: PlaybackTransition) async throws {
        switch transition.reason {
        case .crossfade:
            guard capabilities.canCrossfade else { return }
            player.transition = .crossfade(duration: max(0, transition.duration))
        case .gapless, .hardCut:
            player.transition = .none
        }
    }
}
