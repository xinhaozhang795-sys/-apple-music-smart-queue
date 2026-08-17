import Foundation

/// Builds a short queue sequence while preserving the existing candidate score.
/// Transition quality is used only as a local tie-breaker between otherwise
/// competitive candidates, keeping user preference and policy scoring primary.
public struct QueueSequencePlanner: Sendable {
    public init() {}

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
            let bestIndex = remaining.indices.min { lhs, rhs in
                let left = transitionScore(from: previousFeatures, to: remaining[lhs].candidate.audioFeatures)
                let right = transitionScore(from: previousFeatures, to: remaining[rhs].candidate.audioFeatures)
                let leftValue = combinedValue(remaining[lhs], transition: left)
                let rightValue = combinedValue(remaining[rhs], transition: right)

                if leftValue != rightValue { return leftValue > rightValue }
                if remaining[lhs].score != remaining[rhs].score {
                    return remaining[lhs].score > remaining[rhs].score
                }
                return remaining[lhs].candidate.id < remaining[rhs].candidate.id
            }

            guard let bestIndex else { break }
            let selected = remaining.remove(at: bestIndex)
            previousFeatures = selected.candidate.audioFeatures
            result.append(selected)
        }

        return result
    }

    private func transitionScore(
        from current: AudioFeatures?,
        to candidate: AudioFeatures?
    ) -> Double {
        TransitionScorer().score(
            TransitionContext(current: current, candidate: candidate)
        ).overall
    }

    private func combinedValue(
        _ candidate: ScoredCandidate,
        transition: Double
    ) -> Double {
        candidate.score + transition * 0.05
    }
}
