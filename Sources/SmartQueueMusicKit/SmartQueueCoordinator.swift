import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class SmartQueueCoordinator {
    public let candidateProvider: MusicCandidateProvider
    public let queueController: MusicQueueController
    public let planner: QueuePlanner

    public init(policy: QueuePolicy = QueuePolicy()) {
        self.candidateProvider = MusicCandidateProvider()
        self.queueController = MusicQueueController()
        self.planner = QueuePlanner(policy: policy)
    }

    /// Builds the next batch without changing playback.
    /// This separation makes the recommendation engine testable before we
    /// connect automatic queue mutation to the live player.
    public func makeNextBatch(
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String> = [],
        recentArtistNames: Set<String> = []
    ) async throws -> [ScoredCandidate] {
        async let recommendations = candidateProvider.personalRecommendations()
        async let recent = candidateProvider.recentlyPlayed()

        let recommendedCandidates = try await recommendations
        let recentCandidates = try await recent
        let candidates = recommendedCandidates + recentCandidates

        return planner.plan(
            candidates: candidates,
            current: current,
            activeQueueTrackIDs: activeQueueTrackIDs,
            recentArtistNames: recentArtistNames
        )
    }

    /// Explicitly replaces the system Music queue with the supplied IDs.
    /// V0.1 keeps this operation explicit because SystemMusicPlayer exposes
    /// less queue introspection than ApplicationMusicPlayer.
    public func loadBatch(_ candidates: [ScoredCandidate], play: Bool = false) async throws {
        let ids = candidates.map(\.candidate.id)
        try await queueController.setQueue(trackIDs: ids, play: play)
    }
}
