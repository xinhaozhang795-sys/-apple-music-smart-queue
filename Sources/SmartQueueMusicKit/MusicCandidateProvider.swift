import Foundation
import MusicKit
import SmartQueueDomain

public struct MusicCandidateProvider: MusicCandidateSource, Sendable {
    public init() {}

    /// Fetches Apple Music's personalized recommendation containers and expands
    /// recommended albums/playlists into playable tracks.
    public func personalRecommendations(limit: Int = 25) async throws -> [TrackCandidate] {
        var request = MusicPersonalRecommendationsRequest()
        request.limit = limit
        let response = try await request.response()

        var candidates: [TrackCandidate] = []
        candidates.reserveCapacity(limit * 5)

        for recommendation in response.recommendations {
            for item in recommendation.items {
                switch item {
                case .album(let album):
                    candidates.append(contentsOf: try await tracks(in: album))
                case .playlist(let playlist):
                    candidates.append(contentsOf: try await tracks(in: playlist))
                case .station:
                    continue
                @unknown default:
                    continue
                }
            }
        }

        return candidates
    }

    public func personalRecommendations() async throws -> [TrackCandidate] {
        try await personalRecommendations(limit: 25)
    }

    /// Delegates recently-played retrieval to the shared listening-history
    /// provider so there is a single source of truth for this MusicKit query.
    public func recentlyPlayed() async throws -> [TrackCandidate] {
        try await ListeningHistoryProvider().recentlyPlayedSongs()
    }

    private func tracks(in album: Album) async throws -> [TrackCandidate] {
        var request = MusicCatalogResourceRequest<Album>(
            matching: \.id,
            equalTo: album.id
        )
        request.properties = [.tracks]
        request.limit = 1

        let response = try await request.response()
        return response.items
            .flatMap { $0.tracks ?? [] }
            .compactMap { track in
                guard case .song(let song) = track else { return nil }
                return makeCandidate(song, source: .personalRecommendation)
            }
    }

    private func tracks(in playlist: Playlist) async throws -> [TrackCandidate] {
        var request = MusicCatalogResourceRequest<Playlist>(
            matching: \.id,
            equalTo: playlist.id
        )
        request.properties = [.tracks]
        request.limit = 1

        let response = try await request.response()
        return response.items
            .flatMap { $0.tracks ?? [] }
            .compactMap { track in
                guard case .song(let song) = track else { return nil }
                return makeCandidate(song, source: .personalRecommendation)
            }
    }

    private func makeCandidate(_ song: Song, source: CandidateSource) -> TrackCandidate {
        TrackCandidate(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            source: source,
            freshness: freshness(for: song.lastPlayedDate)
        )
    }

    private func freshness(for lastPlayedDate: Date?) -> Double {
        guard let lastPlayedDate else { return 1.0 }
        let days = max(0, Date().timeIntervalSince(lastPlayedDate) / 86_400)
        return min(1.0, days / 30.0)
    }
}
