import Foundation

/// Scores a candidate for both personal relevance and musical flow.
/// Audio features are selection signals only; no audio is decoded or modified.
public struct SmartFlowScorer: Sendable {
    public struct Weights: Sendable {
        public var affinity: Double = 0.30
        public var recommendation: Double = 0.20
        public var continuity: Double = 0.20
        public var discovery: Double = 0.15
        public var freshness: Double = 0.10
        public var diversity: Double = 0.05

        public init() {}
    }

    public let weights: Weights
    public let continuityScorer: ContinuityScorer

    public init(weights: Weights = Weights()) {
        self.weights = weights
        self.continuityScorer = ContinuityScorer()
    }

    public func score(
        candidate: TrackCandidate,
        currentFeatures: AudioFeatures?,
        candidateFeatures: AudioFeatures?,
        recommendationStrength: Double,
        discoveryValue: Double,
        diversityValue: Double
    ) -> Double {
        let continuity = continuityScorer.score(
            from: currentFeatures,
            to: candidateFeatures
        )

        return candidate.affinity * weights.affinity +
            recommendationStrength * weights.recommendation +
            continuity * weights.continuity +
            discoveryValue * weights.discovery +
            candidate.freshness * weights.freshness +
            diversityValue * weights.diversity
    }
}
