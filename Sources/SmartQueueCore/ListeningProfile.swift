import Foundation

public struct ListeningProfile: Sendable, Hashable {
    public let preferredEnergy: Double
    public let preferredValence: Double
    public let preferredDanceability: Double

    public init(
        preferredEnergy: Double = 0.5,
        preferredValence: Double = 0.5,
        preferredDanceability: Double = 0.5
    ) {
        self.preferredEnergy = Self.clamp(preferredEnergy)
        self.preferredValence = Self.clamp(preferredValence)
        self.preferredDanceability = Self.clamp(preferredDanceability)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0.5 }
        return min(1, max(0, value))
    }
}
