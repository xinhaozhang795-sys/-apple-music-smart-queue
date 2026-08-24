import SmartQueueCore
import SmartQueueDomain

public enum CandidateDecisionAction: String, Sendable, Hashable {
    case insert
    case defer
    case discoverLater
}

public struct CandidateDecision: Sendable, Hashable {
    public let candidateID: String
    public let action: CandidateDecisionAction
    public let confidence: Double
    public let contextualFit: Double
    public let reason: String

    public init(
        candidateID: String,
        action: CandidateDecisionAction,
        confidence: Double,
        contextualFit: Double,
        reason: String
    ) {
        self.candidateID = candidateID
        self.action = action
        self.confidence = Self.clamp(confidence)
        self.contextualFit = Self.clamp(contextualFit)
        self.reason = reason
    }

    private static func clamp(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

/// Adapts existing candidate and continuity signals to the active SessionContext.
/// It intentionally does not decide an exact queue position yet. Position planning
/// belongs to the next queue-planning stage once the session trajectory is modeled.
public struct ContextualCandidateEvaluator: Sendable {
    public let continuityScorer: ContinuityScorer
    public let insertThreshold: Double
    public let deferThreshold: Double

    public init(
        continuityScorer: ContinuityScorer = ContinuityScorer(),
        insertThreshold: Double = 0.72,
        deferThreshold: Double = 0.48
    ) {
        self.continuityScorer = continuityScorer
        self.insertThreshold = min(1, max(0, insertThreshold))
        self.deferThreshold = min(self.insertThreshold, max(0, deferThreshold))
    }

    public func evaluate(
        candidate: TrackCandidate,
        candidateFeatures: AudioFeatures?,
        currentFeatures: AudioFeatures?,
        session: SessionContext
    ) -> CandidateDecision {
        if session.contains(trackID: candidate.id) {
            return CandidateDecision(
                candidateID: candidate.id,
                action: .defer,
                confidence: 1,
                contextualFit: 0,
                reason: "Already present in the active queue."
            )
        }

        let continuity = continuityScorer.score(from: currentFeatures, to: candidateFeatures)
        let moodFit = moodFit(candidateFeatures, session.mood)
        let preferenceFit = min(1, max(0, candidate.affinity))
        let freshness = min(1, max(0, candidate.freshness))

        // Current listening context dominates discovery. Exploration can help a
        // discovery candidate, but it cannot override a poor contextual fit.
        let contextualFit = weightedAverage([
            (continuity, 0.35),
            (moodFit, 0.35),
            (preferenceFit, 0.20),
            (freshness, 0.10)
        ])

        if contextualFit >= insertThreshold {
            return CandidateDecision(
                candidateID: candidate.id,
                action: .insert,
                confidence: contextualFit,
                contextualFit: contextualFit,
                reason: "Fits the current listening context strongly enough to consider insertion."
            )
        }

        if contextualFit >= deferThreshold {
            return CandidateDecision(
                candidateID: candidate.id,
                action: .defer,
                confidence: 1 - abs(contextualFit - 0.5),
                contextualFit: contextualFit,
                reason: "Potentially suitable, but not strong enough to disturb the current listening flow."
            )
        }

        let discoveryCandidate = candidate.source == .discovery || candidate.explorationValue > 0.6
        return CandidateDecision(
            candidateID: candidate.id,
            action: discoveryCandidate ? .discoverLater : .defer,
            confidence: 1 - contextualFit,
            contextualFit: contextualFit,
            reason: discoveryCandidate
                ? "May match the user's taste, but does not currently fit the active session atmosphere."
                : "Does not fit the active session strongly enough for insertion."
        )
    }

    private func moodFit(_ features: AudioFeatures?, _ mood: SessionMood) -> Double {
        guard let features else { return 0.5 }
        var values: [Double] = []

        if let valence = features.valence {
            values.append(1 - min(abs(valence - mood.valence), 1))
        }
        if let energy = features.energy {
            values.append(1 - min(abs(energy - mood.energy), 1))
        }
        if let danceability = features.danceability {
            values.append(1 - min(abs(danceability - mood.danceability), 1))
        }

        guard !values.isEmpty else { return 0.5 }
        let raw = values.reduce(0, +) / Double(values.count)
        return mood.confidence == 0 ? 0.5 + (raw - 0.5) * 0.5 : raw
    }

    private func weightedAverage(_ values: [(Double, Double)]) -> Double {
        let totalWeight = values.reduce(0) { $0 + $1 }
        guard totalWeight > 0 else { return 0.5 }
        return values.reduce(0) { $0 + $1.0 * $1.1 } / totalWeight
    }
}
