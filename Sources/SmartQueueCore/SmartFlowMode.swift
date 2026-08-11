import Foundation

/// High-level listening intent used by the Smart Queue scorer.
public enum SmartFlowMode: String, CaseIterable, Sendable {
    case smooth
    case discovery
    case energyFlow
    case chill
    case surprise
    case party

    public var policy: QueuePolicy {
        switch self {
        case .smooth:
            return QueuePolicy(personalPreferenceWeight: 0.30, appleRecommendationWeight: 0.18, continuityWeight: 0.28, explorationWeight: 0.08, freshnessWeight: 0.10, diversityWeight: 0.06, duplicatePenalty: 0.20, artistRepeatPenalty: 0.16)
        case .discovery:
            return QueuePolicy(personalPreferenceWeight: 0.24, appleRecommendationWeight: 0.22, continuityWeight: 0.14, explorationWeight: 0.26, freshnessWeight: 0.10, diversityWeight: 0.04, duplicatePenalty: 0.18, artistRepeatPenalty: 0.18)
        case .energyFlow:
            return QueuePolicy(personalPreferenceWeight: 0.26, appleRecommendationWeight: 0.16, continuityWeight: 0.34, explorationWeight: 0.08, freshnessWeight: 0.08, diversityWeight: 0.08, duplicatePenalty: 0.18, artistRepeatPenalty: 0.12)
        case .chill:
            return QueuePolicy(personalPreferenceWeight: 0.32, appleRecommendationWeight: 0.16, continuityWeight: 0.30, explorationWeight: 0.06, freshnessWeight: 0.10, diversityWeight: 0.06, duplicatePenalty: 0.18, artistRepeatPenalty: 0.14)
        case .surprise:
            return QueuePolicy(personalPreferenceWeight: 0.20, appleRecommendationWeight: 0.16, continuityWeight: 0.10, explorationWeight: 0.34, freshnessWeight: 0.12, diversityWeight: 0.08, duplicatePenalty: 0.16, artistRepeatPenalty: 0.22)
        case .party:
            return QueuePolicy(personalPreferenceWeight: 0.28, appleRecommendationWeight: 0.20, continuityWeight: 0.30, explorationWeight: 0.08, freshnessWeight: 0.06, diversityWeight: 0.08, duplicatePenalty: 0.20, artistRepeatPenalty: 0.18)
        }
    }
}
