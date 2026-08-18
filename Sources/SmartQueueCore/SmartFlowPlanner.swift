import Foundation

/// Plans a short listening path instead of selecting every track independently.
/// The greedy look-ahead keeps the queue varied while preserving the strongest
/// candidate score at each step.
public struct SmartFlowPlanner: Sendable {
    public let mode: SmartFlowMode

    public init(mode: SmartFlowMode = .smooth) {
        self.mode = mode
    }

    public func plan(
        candidates: [TrackCandidate],
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String> = [],
        recentArtistNames: Set<String> = [],
        count: Int? = nil
    ) -> [ScoredCandidate] {
        let policy = mode.policy
        let scorer = ScoringEngine(policy: policy)
        let limit = max(0, count ?? policy.refillBatchSize)
        guard limit > 0 else { return [] }

        var remaining = candidates.filter { $0.id != current.trackID }
        var selected: [ScoredCandidate] = []
        selected.reserveCapacity(min(limit, remaining.count))
        var usedIDs = activeQueueTrackIDs
        var usedArtists = recentArtistNames
        var previous = current

        while selected.count < limit && !remaining.isEmpty {
            let ranked = scorer.rank(
                remaining,
                current: previous,
                activeQueueTrackIDs: usedIDs,
                recentArtistNames: usedArtists
            )

            guard let best = ranked.first(where: { !usedIDs.contains($0.id) }) else { break }
            selected.append(best)
            usedIDs.insert(best.id)
            usedArtists.insert(best.candidate.artistName)
            previous = CurrentTrackContext(
                trackID: best.candidate.id,
                title: best.candidate.title,
                artistName: best.candidate.artistName,
                audioFeatures: best.candidate.audioFeatures
            )
            remaining.removeAll { $0.id == best.id }
        }

        return selected
    }
}
