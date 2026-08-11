import Foundation

public struct ListeningProfile: Sendable, Hashable {
    public let preferredEnergy: Double
    public let preferredValence: Double
    public let preferredDanceability: Double

    public init(preferredEnergy: Double = 0.5, preferredValence: Double = 0.5, preferredDanceability: Double = 0.5) {
        self.preferredEnergy = Self.clamp(preferredEnergy)
        self.preferredValence = Self.clamp(preferredValence)
        self.preferredDanceability = Self.clamp(preferredDanceability)
    }

    private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
}

/// Optional audio features. Missing values remain nil rather than being guessed.
public struct AudioFeatures: Sendable, Hashable {
    public let bpm: Double?
    public let key: Int?
    public let energy: Double?
    public let valence: Double?
    public let danceability: Double?

    public init(bpm: Double? = nil, key: Int? = nil, energy: Double? = nil, valence: Double? = nil, danceability: Double? = nil) {
        self.bpm = bpm
        self.key = key
        self.energy = energy
        self.valence = valence
        self.danceability = danceability
    }
}
