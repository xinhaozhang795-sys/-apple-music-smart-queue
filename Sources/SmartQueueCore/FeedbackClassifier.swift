import Foundation

/// Interprets raw playback events as recommendation signals.
/// The classifier deliberately keeps playback mechanics separate from taste learning.
public struct FeedbackClassifier: Sendable {
    public enum Signal: Equatable, Sendable {
        case strongPositive
        case positive
        case neutral
        case negative
        case strongNegative
    }

    public init() {}

    public func classify(_ event: ListeningEvent) -> Signal {
        switch event.outcome {
        case .favorited, .replayed:
            return .strongPositive
        case .completed:
            return .positive
        case .started:
            return .neutral
        case .skipped:
            let progress = event.progress ?? 0
            if progress < 0.20 { return .strongNegative }
            if progress < 0.50 { return .negative }
            return .neutral
        }
    }

    /// Converts a classified signal into a normalized learning strength.
    public func learningSignal(for event: ListeningEvent) -> Double {
        switch classify(event) {
        case .strongPositive: return 1.0
        case .positive: return 0.75
        case .neutral: return 0.0
        case .negative: return -0.5
        case .strongNegative: return -1.0
        }
    }
}
