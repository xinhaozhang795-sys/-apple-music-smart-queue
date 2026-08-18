import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackContextProvider {
    private let player: ApplicationMusicPlayer

    public init(player: ApplicationMusicPlayer = .shared) {
        self.player = player
    }

    /// Returns the track currently known to the application Music player.
    public var currentTrackID: String? {
        player.queue.currentEntry?.id
    }

    public var isPlaying: Bool {
        player.state.playbackStatus == .playing
    }
}
