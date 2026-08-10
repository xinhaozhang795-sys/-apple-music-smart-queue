import Foundation

public struct ScoringEngine: Sendable {
    public let policy: QueuePolicy

    public init(policy: QueuePolicy = QueuePolicy()) {
        self.policy = policy
    }

    public func score(
        _ candidate: TrackCandidate,
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String>,
        recentArtistNames: Set<String>
    ) -> ScoredCandidate {
        let recommendation = candidate.source == .personalRecommendation ? 1.0 : 0.0
        let duplicate = activeQueueTrackIDs.contains(candidate.id) ? 1.0 : 0.0
        let artistRepeat = recentArtistNames.contains(candidate.artistName) ? 1.0 : 0.0

        let raw =
            candidate.affinity * policy.personalPreferenceWeight +
            recommendation * policy.appleRecommendationWeight +
            candidate.continuity * policy.continuityWeight +
            candidate.explorationValue * policy.explorationWeight +
            candidate.freshness * policy.freshnessWeight +
            candidate.diversity * policy.diversityWeight -
            duplicate * policy.duplicatePenalty -
            artistRepeat * policy.artistRepeatPenalty

        return ScoredCandidate(candidate: candidate, score: raw)
    }

    public func rank(
        _ candidates: [TrackCandidate],
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String>,
        recentArtistNames: Set<String>
    ) -> [ScoredCandidate] {
        var scored: [ScoredCandidate] = []
        scored.reserveCapacity(candidates.count)

        for candidate in candidates {
            scored.append(
                score(
                    candidate,
                    current: current,
                    activeQueueTrackIDs: activeQueueTrackIDs,
                    recentArtistNames: recentArtistNames
                )
            )
        }

        scored.sort { $0.score > $1.score }
        return scored
    }
}
