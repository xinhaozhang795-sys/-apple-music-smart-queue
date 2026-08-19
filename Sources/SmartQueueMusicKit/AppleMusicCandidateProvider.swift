import Foundation
import MusicKit
import SmartQueueDomain

public struct AppleMusicCandidateProvider: Sendable {
    private let provider: MusicCandidateProvider

    public init() {
        self.provider = MusicCandidateProvider()
    }

    /// Loads the user's current personalized recommendation catalog and maps its
    /// recommendation containers into the platform-independent queue model.
    public func personalizedCandidates() async throws -> [TrackCandidate] {
        try await provider.personalRecommendations()
    }
}
