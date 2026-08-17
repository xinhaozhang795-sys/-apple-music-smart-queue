import Foundation

/// Builds a short queue sequence while preserving the existing candidate score.
/// Transition quality is used only as a local tie-breaker between otherwise
/// competitive candidates, keeping user preference and policy scoring primary.
public struct QueueSequencePlanner: Sendable {
    private let transitionScorer: TransitionScorer

    public init(transitionScorer: TransitionScorer = TransitionScorer()) {
        self.transitionScorer = transitionScorer
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
        let transition = transitionScorer.score(
            TransitionContext(current: previousFeatures, candidate: candidate.candidate.audioFeatures)
        ).overall
        return candidate.score + transition * 0.05
    }

    private func tieBreak(
        _ lhs: ScoredCandidate,
        before rhs: ScoredCandidate
    ) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.candidate.id < rhs.candidate.id
    }
}
