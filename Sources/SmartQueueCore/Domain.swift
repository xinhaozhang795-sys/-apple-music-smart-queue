import Foundation

public struct TrackCandidate: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let source: CandidateSource
    public let affinity: Double
    public let continuity: Double
    public let freshness: Double
    public let explorationValue: Double
    public let diversity: Double
    public let audioFeatures: AudioFeatures?

    public init(
        id: String,
        title: String,
        artistName: String,
        source: CandidateSource,
        affinity: Double = 0,
        continuity: Double = 0,
        freshness: Double = 0,
        explorationValue: Double = 0,
        diversity: Double = 0,
        audioFeatures: AudioFeatures? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.source = source
        self.affinity = affinity
        self.continuity = continuity
        self.freshness = freshness
        self.explorationValue = explorationValue
        self.diversity = diversity
        self.audioFeatures = audioFeatures
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
    public let audioFeatures: AudioFeatures?

    public init(
        trackID: String,
        title: String,
        artistName: String,
        artistID: String? = nil,
        audioFeatures: AudioFeatures? = nil
    ) {
        self.trackID = trackID
        self.title = title
        self.artistName = artistName
        self.artistID = artistID
        self.audioFeatures = audioFeatures
    }
}

public struct QueuePolicy: Sendable {
    public var targetSize: Int
    public var refillThreshold: Int
    public var refillBatchSize: Int

    // Smart Flow weights. These sum to 1.0 before repeat penalties.
    public var personalPreferenceWeight: Double
    public var appleRecommendationWeight: Double
    public var continuityWeight: Double
    public var explorationWeight: Double
    public var freshnessWeight: Double
    public var diversityWeight: Double
    public var transitionWeight: Double

    public var duplicatePenalty: Double
    public var artistRepeatPenalty: Double

    public var personalRecommendationWeight: Double { appleRecommendationWeight }
    public var affinityWeight: Double { personalPreferenceWeight }

    public init(
        targetSize: Int = 8,
        refillThreshold: Int = 3,
        refillBatchSize: Int = 5,
        personalPreferenceWeight: Double = 0.30,
        appleRecommendationWeight: Double = 0.20,
        continuityWeight: Double = 0.20,
        explorationWeight: Double = 0.15,
        freshnessWeight: Double = 0.10,
        diversityWeight: Double = 0.05,
        transitionWeight: Double = 0.05,
        duplicatePenalty: Double = 0.10,
        artistRepeatPenalty: Double = 0.10
    ) {
        self.targetSize = targetSize
        self.refillThreshold = refillThreshold
        self.refillBatchSize = refillBatchSize
        self.personalPreferenceWeight = personalPreferenceWeight
        self.appleRecommendationWeight = appleRecommendationWeight
        self.continuityWeight = continuityWeight
        self.explorationWeight = explorationWeight
        self.freshnessWeight = freshnessWeight
        self.diversityWeight = diversityWeight
        self.transitionWeight = transitionWeight
        self.duplicatePenalty = duplicatePenalty
        self.artistRepeatPenalty = artistRepeatPenalty
    }
}

public struct ScoredCandidate: Identifiable, Sendable {
    public let id: String
    public let candidate: TrackCandidate
    public let score: Double
    public let transitionScore: Double

    public init(candidate: TrackCandidate, score: Double, transitionScore: Double = 0.5) {
        self.id = candidate.id
        self.candidate = candidate
        self.score = score
        self.transitionScore = transitionScore
    }
}
