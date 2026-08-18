import Foundation
@preconcurrency import MusicKit
import SmartQueueCore

public enum MusicQueueControllerError: Error {
    case noPlayableTracks
}

@MainActor
public final class MusicQueueController: MusicPlaybackAdapter {
    private let player: ApplicationMusicPlayer

    public init(player: ApplicationMusicPlayer = .shared) {
        self.player = player
    }

    /// Loads a new application Music queue from Apple Music song IDs.
    ///
    /// This is an explicit queue replacement operation. Auto-refill should use
    /// `appendToQueue(trackIDs:)` so the existing Up Next queue is preserved.
    public func setQueue(trackIDs: [String], play: Bool = false) async throws {
        let songs = try await resolveSongs(trackIDs)
        player.queue = ApplicationMusicPlayer.Queue(for: songs)
        if play {
            try await player.play()
        }
    }

    /// Appends playable songs to the existing application Music queue.
    /// The currently playing item and existing Up Next entries are preserved.
    public func appendToQueue(trackIDs: [String]) async throws {
        let songs = try await resolveSongs(trackIDs)
        guard !songs.isEmpty else { throw MusicQueueControllerError.noPlayableTracks }
        try await player.queue.insert(songs, position: .tail)
    }

    public func play() async throws {
        try await player.play()
    }

    public func pause() {
        player.pause()
    }

    public var currentTrackID: String? {
        player.queue.currentEntry?.id
    }

    public var isPlaying: Bool {
        player.state.playbackStatus == .playing
    }

    /// ApplicationMusicPlayer exposes its queue entries directly, so this count
    /// reflects the actual queue rather than a separately maintained estimate.
    public var queueCount: Int {
        player.queue.entries.count
    }

    public var currentEntry: MusicPlayer.Queue.Entry? {
        player.queue.currentEntry
    }

    public var playbackStatus: MusicPlayer.PlaybackStatus {
        player.state.playbackStatus
    }

    private func resolveSongs(_ trackIDs: [String]) async throws -> [Song] {
        let ids = trackIDs.map(MusicItemID.init(rawValue:))
        guard !ids.isEmpty else { throw MusicQueueControllerError.noPlayableTracks }

        var request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: ids)
        request.limit = ids.count
        let response = try await request.response()

        let songs = ids.compactMap { id in
            response.items.first { $0.id == id }
        }
        guard !songs.isEmpty else { throw MusicQueueControllerError.noPlayableTracks }
        return songs
    }
}
