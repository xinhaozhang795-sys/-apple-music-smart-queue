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
        self.overall = overall
        self.bpm = bpm
        self.energy = energy
        self.valence = valence
        self.danceability = danceability
    }
}
