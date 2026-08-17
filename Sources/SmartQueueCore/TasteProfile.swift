import Foundation

/// Compact long-term taste state. Values are normalized to 0...1.
public struct TasteProfile: Equatable, Sendable {
    public let preferredEnergy: Double
    public let preferredValence: Double
    public let preferredDanceability: Double
    public let explorationPreference: Double

    public init(
        preferredEnergy: Double = 0.5,
        preferredValence: Double = 0.5,
        preferredDanceability: Double = 0.5,
        explorationPreference: Double = 0.5
    ) {
        self.preferredEnergy = Self.clamp(preferredEnergy)
        self.preferredValence = Self.clamp(preferredValence)
        self.preferredDanceability = Self.clamp(preferredDanceability)
        self.explorationPreference = Self.clamp(explorationPreference)
    }

    public func updated(with features: AudioFeatures, signal: Double, learningRate: Double = 0.08) -> TasteProfile {
        let rate = Self.clamp(learningRate)
        let signedWeight = Self.clampSigned(signal)

        func learn(_ current: Double, _ observed: Double?) -> Double {
            guard let observed else { return current }
            return Self.clamp(current + (observed - current) * rate * signedWeight)
        }

        return TasteProfile(
            preferredEnergy: learn(preferredEnergy, features.energy),
            preferredValence: learn(preferredValence, features.valence),
            preferredDanceability: learn(preferredDanceability, features.danceability),
            explorationPreference: explorationPreference
        )
    }

    private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
    private static func clampSigned(_ value: Double) -> Double { min(1, max(-1, value)) }
}
