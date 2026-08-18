import Foundation

public enum TransitionStrategy: String, Sendable, Equatable {
    case naturalCut
    case crossfade
}

public struct TransitionDecision: Sendable, Equatable {
    public let score: TransitionScore
    public let strategy: TransitionStrategy

    public init(score: TransitionScore, strategy: TransitionStrategy) {
        self.score = score
        self.strategy = strategy
    }
}

/// Converts a transition score into a platform-neutral playback intent.
/// Actual execution remains the responsibility of the platform adapter.
public struct TransitionPlanner: Sendable {
    public let crossfadeThreshold: Double

    public init(crossfadeThreshold: Double = 0.65) {
        self.crossfadeThreshold = min(max(crossfadeThreshold, 0), 1)
    }

    public func decide(_ context: TransitionContext) -> TransitionDecision {
        let score = TransitionScorer().score(context)
        let strategy: TransitionStrategy = score.overall >= crossfadeThreshold ? .crossfade : .naturalCut
        return TransitionDecision(score: score, strategy: strategy)
    }
}
