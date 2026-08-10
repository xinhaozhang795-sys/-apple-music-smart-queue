import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackContextProvider {
    private let player = SystemMusicPlayer.shared

    public init() {}

    /// Returns the track currently known to the system player.
    /// The app intentionally treats the system player as the playback authority.
    public var currentTrackID: String? {
        player.queue.currentEntry?.id.rawValue
    }

    public var isPlaying: Bool {
        player.state.playbackStatus == .playing
    }
}
