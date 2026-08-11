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
    /// This is an explicit queue replacement operation. Auto-refill should use
    /// `appendToQueue(trackIDs:)` so the existing Up Next queue is preserved.
    public func setQueue(trackIDs: [String], play: Bool = false) async throws {
        let songs = try await resolveSongs(trackIDs)
        player.queue = MusicPlayer.Queue(for: songs)
        if play {
            try await player.play()
        }
    }

    /// Appends playable songs to the existing SystemMusicPlayer queue.
    /// The currently playing item and existing Up Next entries are preserved.
    public func appendToQueue(trackIDs: [String]) async throws {
        let songs = try await resolveSongs(trackIDs)
        for song in songs {
            player.queue.insert(song, position: .tail)
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
        request.options = [.findEquivalents]
        let response = try await request.response()

        let songs = ids.compactMap { id in
            response.items.first { $0.id == id }
        }
        guard !songs.isEmpty else { throw MusicQueueControllerError.noPlayableTracks }
        return songs
    }
}
