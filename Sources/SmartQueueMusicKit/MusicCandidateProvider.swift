import Foundation
import MusicKit
import SmartQueueCore

public struct MusicCandidateProvider {
    public init() {}

    public func personalRecommendations(limit: Int = 25) async throws -> [QueueCandidate] {
        var request = MusicPersonalRecommendationsRequest()
        request.limit = limit
        let response = try await request.response()

        return response.recommendations.flatMap { recommendation in
            recommendation.items.compactMap(Self.makeCandidate)
        }
    }

    public func recentlyPlayed(limit: Int = 25) async throws -> [QueueCandidate] {
        var request = MusicRecentlyPlayedRequest()
        request.limit = limit
        let response = try await request.response()

        return response.items.compactMap(Self.makeCandidate)
    }

    private static func makeCandidate(_ item: MusicCatalogSearchable) -> QueueCandidate? {
        guard let song = item as? Song else { return nil }

        return QueueCandidate(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            albumName: song.albumTitle,
            genres: song.genreNames,
            source: .appleMusicRecommendation,
            metadata: CandidateMetadata(
                duration: song.duration,
                releaseDate: song.releaseDate
            )
        )
    }
}
