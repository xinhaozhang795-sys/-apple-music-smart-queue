import Foundation

/// Scores the musical continuity of A → B without making platform playback decisions.
public struct TransitionScorer: Sendable {
    public init() {}

    public func score(_ context: TransitionContext) -> TransitionScore {
        guard let current = context.current, let candidate = context.candidate else {
            return TransitionScore(overall: 0.5, bpm: 0.5, energy: 0.5, valence: 0.5, danceability: 0.5)
        }

        let bpm = normalizedBPMContinuity(current.bpm, candidate.bpm)
        let energy = normalizedDifference(current.energy, candidate.energy)
        let valence = normalizedDifference(current.valence, candidate.valence)
        let danceability = normalizedDifference(current.danceability, candidate.danceability)

        let values = [bpm, energy, valence, danceability]
        let overall = values.reduce(0, +) / Double(values.count)

        return TransitionScore(
            overall: overall,
            bpm: bpm,
            energy: energy,
            valence: valence,
            danceability: danceability
        )
    }

    private func normalizedDifference(_ lhs: Double?, _ rhs: Double?) -> Double {
        guard let lhs, let rhs else { return 0.5 }
        return 1 - min(abs(lhs - rhs), 1)
    }

    private func normalizedBPMContinuity(_ lhs: Double?, _ rhs: Double?) -> Double {
        guard let lhs, let rhs, lhs > 0, rhs > 0 else { return 0.5 }

        // Prefer direct proximity while also recognizing common half/double-time relationships.
        let ratios = [lhs / rhs, rhs / lhs]
        let bestRatioDistance = ratios
            .map { abs(log2($0)) }
            .min() ?? 1

        return max(0, 1 - min(bestRatioDistance, 1))
    }
}
