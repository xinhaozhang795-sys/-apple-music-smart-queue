import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class SmartQueueCoordinator {
    public let candidateProvider: MusicCandidateProvider
    public let queueController: MusicQueueController
    public let playbackEngine: ApplicationMusicPlaybackEngine
    public let planner: QueuePlanner
    public let transitionPlanner: TransitionPlanner

    public init(
        policy: QueuePolicy = QueuePolicy(),
        transitionPlanner: TransitionPlanner = TransitionPlanner()
    ) {
        self.candidateProvider = MusicCandidateProvider()
        self.queueController = MusicQueueController()
        self.playbackEngine = ApplicationMusicPlaybackEngine()
        self.planner = QueuePlanner(policy: policy)
        self.transitionPlanner = transitionPlanner
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

        let candidates = mergeUnique(recommendedCandidates + recentCandidates)

        return planner.plan(
            candidates: candidates,
            current: current,
            activeQueueTrackIDs: activeQueueTrackIDs,
            recentArtistNames: artists
        )
    }

    /// Builds the queue and transition decisions as one deterministic plan.
    public func makeNextPlan(
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String> = [],
        recentArtistNames: Set<String> = []
    ) async throws -> (candidates: [ScoredCandidate], transitionPlan: TransitionPlan) {
        let candidates = try await makeNextBatch(
            current: current,
            activeQueueTrackIDs: activeQueueTrackIDs,
            recentArtistNames: recentArtistNames
        )
        let transitionPlan = TransitionPlan.make(
            current: current,
            candidates: candidates,
            planner: transitionPlanner
        )
        return (candidates, transitionPlan)
    }

    /// Applies the first transition decision and appends the planned tracks.
    ///
    /// ApplicationMusicPlayer exposes one queue-wide transition policy. Therefore
    /// the first edge (current -> next) is applied now. The full TransitionPlan
    /// remains available so future per-edge platform APIs can execute later edges
    /// without changing the core planner.
    public func appendBatch(
        _ candidates: [ScoredCandidate],
        current: CurrentTrackContext
    ) async throws {
        guard !candidates.isEmpty else { return }

        let transitionPlan = TransitionPlan.make(
            current: current,
            candidates: candidates,
            planner: transitionPlanner
        )

        if let decision = transitionPlan.firstDecision {
            try await playbackEngine.apply(
                transition: playbackTransition(for: decision)
            )
        }

        try await queueController.appendToQueue(trackIDs: candidates.map(\.candidate.id))
    }

    /// Explicitly replaces the application Music queue with a planned batch.
    /// The transition is applied before the queue is replaced, matching MusicKit's
    /// documented ordering requirement.
    public func replaceQueue(
        with candidates: [ScoredCandidate],
        current: CurrentTrackContext,
        play: Bool = false
    ) async throws {
        guard !candidates.isEmpty else { return }

        let transitionPlan = TransitionPlan.make(
            current: current,
            candidates: candidates,
            planner: transitionPlanner
        )

        if let decision = transitionPlan.firstDecision {
            try await playbackEngine.apply(
                transition: playbackTransition(for: decision)
            )
        }

        try await queueController.setQueue(
            trackIDs: candidates.map(\.candidate.id),
            play: play
        )
    }

    private func playbackTransition(for decision: TransitionDecision) -> PlaybackTransition {
        switch decision.strategy {
        case .crossfade:
            return PlaybackTransition(duration: 4, reason: .crossfade)
        case .naturalCut:
            return PlaybackTransition(duration: 0, reason: .hardCut)
        }
    }

    private func mergeUnique(_ candidates: [TrackCandidate]) -> [TrackCandidate] {
        var seen = Set<String>()
        return candidates.filter { seen.insert($0.id).inserted }
    }
}
