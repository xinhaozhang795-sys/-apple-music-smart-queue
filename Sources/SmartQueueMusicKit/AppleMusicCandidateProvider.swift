import Foundation
import MusicKit
import SmartQueueCore

public struct AppleMusicCandidateProvider: Sendable {
    public init() {}

    /// Loads the user's current personalized recommendation catalog and maps its songs
    /// into the platform-independent queue model. This layer intentionally does not
    /// perform audio analysis or audio processing.
    public func personalizedCandidates() async throws -> [TrackCandidate] {
        var request = MusicPersonalRecommendationsRequest()
        let response = try await request.response()

        return response.recommendations
            .flatMap { recommendation in
                recommendation.contents.compactMap { content in
                    guard let song = content as? Song else { return nil }
                    return SongMapper().map(song, source: .personalRecommendation)
                }
            }
    }
}
