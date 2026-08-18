import Foundation

/// The transition decision for one edge in a planned queue sequence.
public struct TransitionPlanStep: Sendable, Equatable, Identifiable {
    public let id: String
    public let fromTrackID: String
    public let toTrackID: String
    public let decision: TransitionDecision

    public init(fromTrackID: String, toTrackID: String, decision: TransitionDecision) {
        self.fromTrackID = fromTrackID
        self.toTrackID = toTrackID
        self.decision = decision
        self.id = "\(fromTrackID)->\(toTrackID)"
    }
}

/// Complete transition intelligence for a queue sequence.
///
/// The platform adapter may have a single queue-wide transition setting. In
/// that case the first step controls the upcoming current-track -> next-track
/// edge, while the remaining steps remain available for diagnostics and future
/// per-edge platform capabilities.
public struct TransitionPlan: Sendable, Equatable {
    public let steps: [TransitionPlanStep]

    public init(steps: [TransitionPlanStep] = []) {
        self.steps = steps
    }

    public var firstDecision: TransitionDecision? {
        steps.first?.decision
    }

    public static func make(
        current: CurrentTrackContext,
        candidates: [ScoredCandidate],
        planner: TransitionPlanner = TransitionPlanner()
    ) -> TransitionPlan {
        var steps: [TransitionPlanStep] = []
        steps.reserveCapacity(candidates.count)

        var fromID = current.trackID
        var fromFeatures = current.audioFeatures

        for candidate in candidates {
            let decision = planner.decide(
                TransitionContext(
                    current: fromFeatures,
                    candidate: candidate.candidate.audioFeatures
                )
            )

            steps.append(
                TransitionPlanStep(
                    fromTrackID: fromID,
                    toTrackID: candidate.id,
                    decision: decision
                )
            )

            fromID = candidate.id
            fromFeatures = candidate.candidate.audioFeatures
        }

        return TransitionPlan(steps: steps)
    }
}
