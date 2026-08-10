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
            recommendation * policy.personalRecommendationWeight +
            candidate.affinity * policy.affinityWeight +
            candidate.continuity * policy.continuityWeight +
            candidate.freshness * policy.freshnessWeight -
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
        candidates
            .map {
                score(
                    $0,
                    current: current,
                    activeQueueTrackIDs: activeQueueTrackIDs,
                    recentArtistNames: recentArtistNames
                )
            }
            .sorted { $0.score > $1.score }
    }
}
