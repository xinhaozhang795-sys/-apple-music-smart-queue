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

    /// Builds the next batch from live Apple Music recommendations and recent plays.
    /// This method only plans; it does not mutate the live player queue.
    public func makeNextBatch(
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String> = [],
        recentArtistNames: Set<String> = []
    ) async throws -> [ScoredCandidate] {
        async let recommendations = candidateProvider.personalRecommendations()
        async let recent = candidateProvider.recentlyPlayed()

        let recommendedCandidates = try await recommendations
        let recentCandidates = try await recent
        let derivedRecentArtists = Set(recentCandidates.map(\.artistName))
        let artists = recentArtistNames.union(derivedRecentArtists)

        // Recommendations and history can contain the same track. Keep one copy
        // before scoring so a duplicate source cannot distort ranking.
        let candidates = mergeUnique(recommendedCandidates + recentCandidates)

        return planner.plan(
            candidates: candidates,
            current: current,
            activeQueueTrackIDs: activeQueueTrackIDs,
            recentArtistNames: artists
        )
    }

    /// Appends a planned batch to the existing system Music queue.
    /// Playback remains explicit so planning can be tested independently.
    public func appendBatch(_ candidates: [ScoredCandidate]) async throws {
        let ids = candidates.map(\.candidate.id)
        guard !ids.isEmpty else { return }
        try await queueController.appendToQueue(trackIDs: ids)
    }

    /// Explicitly replaces the system Music queue with a planned batch.
    /// This is intentionally separate from AutoRefill.
    public func replaceQueue(with candidates: [ScoredCandidate], play: Bool = false) async throws {
        let ids = candidates.map(\.candidate.id)
        guard !ids.isEmpty else { return }
        try await queueController.setQueue(trackIDs: ids, play: play)
    }

    private func mergeUnique(_ candidates: [TrackCandidate]) -> [TrackCandidate] {
        var seen = Set<String>()
        return candidates.filter { seen.insert($0.id).inserted }
    }
}
