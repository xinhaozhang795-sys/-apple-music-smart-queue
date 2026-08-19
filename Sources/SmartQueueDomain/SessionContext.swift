import Foundation
import SmartQueueCore

/// The active listening period in which queue decisions must preserve the user's
/// current listening experience. A session begins when intentional playback
/// starts and ends when playback is explicitly stopped or the listening period
/// is closed by the application.
public struct SessionContext: Sendable, Hashable {
    public let id: UUID
    public let startedAt: Date
    public let currentTrack: SessionTrackSnapshot?
    public let recentTracks: [SessionTrackSnapshot]
    public let queue: [SessionTrackSnapshot]
    public let mood: SessionMood
    public let energyTrend: SessionEnergyTrend
    public let exploration: SessionExplorationState
    public let feedback: SessionFeedbackState

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        currentTrack: SessionTrackSnapshot? = nil,
        recentTracks: [SessionTrackSnapshot] = [],
        queue: [SessionTrackSnapshot] = [],
        mood: SessionMood = .neutral,
        energyTrend: SessionEnergyTrend = .stable,
        exploration: SessionExplorationState = .default,
        feedback: SessionFeedbackState = .default
    ) {
        self.id = id
        self.startedAt = startedAt
        self.currentTrack = currentTrack
        self.recentTracks = recentTracks
        self.queue = queue
        self.mood = mood
        self.energyTrend = energyTrend
        self.exploration = exploration
        self.feedback = feedback
    }

    /// Whether a candidate belongs to the currently active queue snapshot.
    public func contains(trackID: String) -> Bool {
        queue.contains { $0.trackID == trackID }
    }
}

public struct SessionTrackSnapshot: Sendable, Hashable, Identifiable {
    public let trackID: String
    public let title: String
    public let artistName: String
    public let artistID: String?
    public let position: Int?

    public var id: String { trackID }

    public init(
        trackID: String,
        title: String,
        artistName: String,
        artistID: String? = nil,
        position: Int? = nil
    ) {
        self.trackID = trackID
        self.title = title
        self.artistName = artistName
        self.artistID = artistID
        self.position = position
    }

    public init(_ context: CurrentTrackContext, position: Int? = nil) {
        self.init(
            trackID: context.trackID,
            title: context.title,
            artistName: context.artistName,
            artistID: context.artistID,
            position: position
        )
    }
}

public struct SessionMood: Sendable, Hashable {
    public let valence: Double
    public let energy: Double
    public let danceability: Double
    public let confidence: Double

    public static let neutral = SessionMood()

    public init(
        valence: Double = 0.5,
        energy: Double = 0.5,
        danceability: Double = 0.5,
        confidence: Double = 0
    ) {
        self.valence = Self.clamp(valence)
        self.energy = Self.clamp(energy)
        self.danceability = Self.clamp(danceability)
        self.confidence = Self.clamp(confidence)
    }

    private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
}

public enum SessionEnergyTrend: String, Sendable, Hashable {
    case rising
    case falling
    case stable
    case unknown
}

public struct SessionExplorationState: Sendable, Hashable {
    public let openness: Double
    public let successfulDiscoveries: Int
    public let rejectedDiscoveries: Int

    public static let `default` = SessionExplorationState()

    public init(
        openness: Double = 0.5,
        successfulDiscoveries: Int = 0,
        rejectedDiscoveries: Int = 0
    ) {
        self.openness = min(1, max(0, openness))
        self.successfulDiscoveries = max(0, successfulDiscoveries)
        self.rejectedDiscoveries = max(0, rejectedDiscoveries)
    }
}

public struct SessionFeedbackState: Sendable, Hashable {
    public let skips: Int
    public let completions: Int
    public let replays: Int

    public static let `default` = SessionFeedbackState()

    public init(skips: Int = 0, completions: Int = 0, replays: Int = 0) {
        self.skips = max(0, skips)
        self.completions = max(0, completions)
        self.replays = max(0, replays)
    }
}
