import Foundation
import MusicKit
import SmartQueueCore

public enum MusicQueueControllerError: Error {
    case noPlayableTracks
}

@MainActor
public final class MusicQueueController: MusicPlaybackAdapter {
    private let player = SystemMusicPlayer.shared

    public init() {}

    /// Loads a new system Music queue from Apple Music song IDs.
    ///
    /// SystemMusicPlayer intentionally remains the playback layer. This controller
    /// does not decode, remix, or transform audio.
    public func setQueue(trackIDs: [String], play: Bool = false) async throws {
        let ids = trackIDs.map(MusicItemID.init(rawValue:))
        guard !ids.isEmpty else { throw MusicQueueControllerError.noPlayableTracks }

        var request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: ids)
        request.options = [.findEquivalents]
        let response = try await request.response()

        let songs = ids.compactMap { response.item(for: $0) }
        guard !songs.isEmpty else { throw MusicQueueControllerError.noPlayableTracks }

        player.queue = MusicPlayer.Queue(for: songs)
        if play {
            try await player.play()
        }
    }

    public func play() async throws {
        try await player.play()
    }

    public func pause() {
        player.pause()
    }

    public var currentTrackID: String? {
        player.queue.currentEntry?.id.rawValue
    }

    public var isPlaying: Bool {
        player.state.playbackStatus == .playing
    }

    public var currentEntry: MusicPlayer.Queue.Entry? {
        player.queue.currentEntry
    }

    public var playbackStatus: MusicPlayer.PlaybackStatus {
        player.state.playbackStatus
    }
}
