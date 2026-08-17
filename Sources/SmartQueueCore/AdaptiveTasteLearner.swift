import Foundation

/// Applies classified listening feedback to long-term taste without coupling
/// storage or playback concerns to the recommendation model.
public struct AdaptiveTasteLearner: Sendable {
    public let classifier: FeedbackClassifier
    public let learningRate: Double

    public init(classifier: FeedbackClassifier = FeedbackClassifier(), learningRate: Double = 0.08) {
        self.classifier = classifier
        self.learningRate = min(1, max(0, learningRate))
    }

    public func update(
        profile: TasteProfile,
        event: ListeningEvent,
        features: AudioFeatures
    ) -> TasteProfile {
        let signal = classifier.learningSignal(for: event)
        guard signal != 0 else { return profile }
        return profile.updated(with: features, signal: signal, learningRate: learningRate)
    }
}
