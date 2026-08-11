import Foundation
import MusicKit
import SmartQueueCore

public struct ListeningHistoryProvider: Sendable {
    public init() {}

    public func recentlyPlayedSongs() async throws -> [TrackCandidate] {
        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = 50
        let response = try await request.response()

        return response.items.map { SongMapper().map($0, source: .recentlyPlayed) }
    }

    public func recentlyPlayedArtistNames() async throws -> Set<String> {
        Set(try await recentlyPlayedSongs().map(\.artistName))
    }
}
