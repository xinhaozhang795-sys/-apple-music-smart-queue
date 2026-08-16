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
        score(
            candidate,
            current: current,
            activeQueueTrackIDs: activeQueueTrackIDs,
            normalizedRecentArtistNames: Self.normalizedArtistNames(recentArtistNames)
        )
    }

    private func score(
        _ candidate: TrackCandidate,
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String>,
        normalizedRecentArtistNames: Set<String>
    ) -> ScoredCandidate {
        let recommendation = candidate.source == .personalRecommendation ? 1.0 : 0.0
        let duplicate = activeQueueTrackIDs.contains(candidate.id) ? 1.0 : 0.0
        let artistRepeat = normalizedRecentArtistNames.contains(Self.normalizeArtistName(candidate.artistName)) ? 1.0 : 0.0

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
        let normalizedRecentArtistNames = Self.normalizedArtistNames(recentArtistNames)

        for candidate in candidates {
            scored.append(
                score(
                    candidate,
                    current: current,
                    activeQueueTrackIDs: activeQueueTrackIDs,
                    normalizedRecentArtistNames: normalizedRecentArtistNames
                )
            )
        }

        scored.sort(by: Self.compare)
        return scored
    }

    public static func normalizeArtistName(_ artistName: String) -> String {
        artistName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public static func normalizedArtistNames(_ artistNames: Set<String>) -> Set<String> {
        Set(artistNames.map(normalizeArtistName))
    }

    private static func compare(_ lhs: ScoredCandidate, _ rhs: ScoredCandidate) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        if lhs.candidate.title != rhs.candidate.title {
            return lhs.candidate.title.lexicographicallyPrecedes(rhs.candidate.title)
        }
        return lhs.id.lexicographicallyPrecedes(rhs.id)
    }
}
