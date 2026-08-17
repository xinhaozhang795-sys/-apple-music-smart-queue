import Foundation

/// Builds a short queue sequence while preserving the existing candidate score.
/// Transition quality is re-evaluated for each adjacent pair without double-counting
/// the transition score that was used during the initial candidate ranking.
public struct QueueSequencePlanner: Sendable {
    private let transitionScorer: TransitionScorer
    private let transitionWeight: Double

    public init(
        transitionScorer: TransitionScorer = TransitionScorer(),
        transitionWeight: Double = 0.05
    ) {
        self.transitionScorer = transitionScorer
        self.transitionWeight = transitionWeight
    }

    public func plan(
        candidates: [ScoredCandidate],
        current: CurrentTrackContext,
        limit: Int
    ) -> [ScoredCandidate] {
        guard limit > 0, !candidates.isEmpty else { return [] }

        var remaining = candidates
        var result: [ScoredCandidate] = []
        result.reserveCapacity(min(limit, candidates.count))

        var previousFeatures = current.audioFeatures

        while result.count < limit, !remaining.isEmpty {
            var bestIndex = remaining.startIndex
            var bestValue = selectionValue(remaining[bestIndex], previousFeatures: previousFeatures)

            for index in remaining.indices.dropFirst() {
                let value = selectionValue(remaining[index], previousFeatures: previousFeatures)
                if value > bestValue ||
                    (value == bestValue && tieBreak(remaining[index], before: remaining[bestIndex])) {
                    bestIndex = index
                    bestValue = value
                }
            }

            let selected = remaining.remove(at: bestIndex)
            previousFeatures = selected.candidate.audioFeatures
            result.append(selected)
        }

        return result
    }

    private func selectionValue(
        _ candidate: ScoredCandidate,
        previousFeatures: AudioFeatures?
    ) -> Double {
        let baseScore = candidate.score - candidate.transitionScore * transitionWeight
        let transition = transitionScorer.score(
            TransitionContext(current: previousFeatures, candidate: candidate.candidate.audioFeatures)
        ).overall
        return baseScore + transition * transitionWeight
    }

    private func tieBreak(
        _ lhs: ScoredCandidate,
        before rhs: ScoredCandidate
    ) -> Bool {
        let lhsBaseScore = lhs.score - lhs.transitionScore * transitionWeight
        let rhsBaseScore = rhs.score - rhs.transitionScore * transitionWeight

        if lhsBaseScore != rhsBaseScore { return lhsBaseScore > rhsBaseScore }
        return lhs.candidate.id < rhs.candidate.id
    }
}
