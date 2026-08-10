import Foundation

/// Descriptive audio features used for selection, not audio processing.
public struct AudioFeatures: Equatable, Sendable {
    public var bpm: Double?
    public var key: String?
    public var energy: Double?
    public var danceability: Double?
    public var valence: Double?
    public var acousticness: Double?
    public var instrumentalness: Double?

    public init(
        bpm: Double? = nil,
        key: String? = nil,
        energy: Double? = nil,
        danceability: Double? = nil,
        valence: Double? = nil,
        acousticness: Double? = nil,
        instrumentalness: Double? = nil
    ) {
        self.bpm = bpm
        self.key = key
        self.energy = energy
        self.danceability = danceability
        self.valence = valence
        self.acousticness = acousticness
        self.instrumentalness = instrumentalness
    }
}

public struct TrackProfile: Equatable, Sendable {
    public let trackID: String
    public let features: AudioFeatures

    public init(trackID: String, features: AudioFeatures) {
        self.trackID = trackID
        self.features = features
    }
}

public struct ContinuityScorer: Sendable {
    public init() {}

    public func score(from current: AudioFeatures?, to candidate: AudioFeatures?) -> Double {
        guard let current, let candidate else { return 0.5 }

        var values: [Double] = []

        if let a = current.energy, let b = candidate.energy {
            values.append(1 - min(abs(a - b), 1))
        }
        if let a = current.danceability, let b = candidate.danceability {
            values.append(1 - min(abs(a - b), 1))
        }
        if let a = current.valence, let b = candidate.valence {
            values.append(1 - min(abs(a - b), 1))
        }
        if let a = current.bpm, let b = candidate.bpm, max(a, b) > 0 {
            values.append(max(0, 1 - abs(a - b) / max(a, b)))
        }

        guard !values.isEmpty else { return 0.5 }
        return values.reduce(0, +) / Double(values.count)
    }
}
