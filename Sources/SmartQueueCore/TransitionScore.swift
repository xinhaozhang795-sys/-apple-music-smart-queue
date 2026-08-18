import Foundation

public struct TransitionScore: Sendable, Equatable {
    public let overall: Double
    public let bpm: Double
    public let energy: Double
    public let valence: Double
    public let danceability: Double

    public init(
        overall: Double,
        bpm: Double,
        energy: Double,
        valence: Double,
        danceability: Double
    ) {
        self.overall = Self.clamp(overall)
        self.bpm = Self.clamp(bpm)
        self.energy = Self.clamp(energy)
        self.valence = Self.clamp(valence)
        self.danceability = Self.clamp(danceability)
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0.5 }
        return min(1, max(0, value))
    }
}
