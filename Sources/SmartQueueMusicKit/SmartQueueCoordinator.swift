import Foundation
import MusicKit
import SmartQueueCore

@available(iOS 18.0, *)
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
    /// ApplicationMusicPlayer has one queue-wide transition policy, so the first
    /// current-track -> next-track edge is the one executed at this queue handoff.
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

    /// Applies the transition before replacing the application queue, matching
    /// MusicKit's documented ordering requirement.
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
