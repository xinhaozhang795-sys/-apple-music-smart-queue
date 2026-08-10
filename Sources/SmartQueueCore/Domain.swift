import Foundation

public struct TrackCandidate: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let source: CandidateSource
    public let affinity: Double
    public let continuity: Double
    public let freshness: Double

    public init(
        id: String,
        title: String,
        artistName: String,
        source: CandidateSource,
        affinity: Double = 0,
        continuity: Double = 0,
        freshness: Double = 0
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.source = source
        self.affinity = affinity
        self.continuity = continuity
        self.freshness = freshness
    }
}

public enum CandidateSource: String, Sendable {
    case personalRecommendation
    case library
    case recentlyPlayed
    case discovery
}

public struct CurrentTrackContext: Sendable {
    public let trackID: String
    public let title: String
    public let artistName: String
    public let artistID: String?

    public init(trackID: String, title: String, artistName: String, artistID: String? = nil) {
        self.trackID = trackID
        self.title = title
        self.artistName = artistName
        self.artistID = artistID
    }
}

public struct QueuePolicy: Sendable {
    public var targetSize: Int
    public var refillThreshold: Int
    public var refillBatchSize: Int
    public var personalRecommendationWeight: Double
    public var affinityWeight: Double
    public var continuityWeight: Double
    public var freshnessWeight: Double
    public var duplicatePenalty: Double
    public var artistRepeatPenalty: Double

    public init(
        targetSize: Int = 8,
        refillThreshold: Int = 3,
        refillBatchSize: Int = 5,
        personalRecommendationWeight: Double = 0.35,
        affinityWeight: Double = 0.25,
        continuityWeight: Double = 0.20,
        freshnessWeight: Double = 0.10,
        duplicatePenalty: Double = 0.10,
        artistRepeatPenalty: Double = 0.10
    ) {
        self.targetSize = targetSize
        self.refillThreshold = refillThreshold
        self.refillBatchSize = refillBatchSize
        self.personalRecommendationWeight = personalRecommendationWeight
        self.affinityWeight = affinityWeight
        self.continuityWeight = continuityWeight
        self.freshnessWeight = freshnessWeight
        self.duplicatePenalty = duplicatePenalty
        self.artistRepeatPenalty = artistRepeatPenalty
    }
}

public struct ScoredCandidate: Identifiable, Sendable {
    public let id: String
    public let candidate: TrackCandidate
    public let score: Double

    public init(candidate: TrackCandidate, score: Double) {
        self.id = candidate.id
        self.candidate = candidate
        self.score = score
    }
}
