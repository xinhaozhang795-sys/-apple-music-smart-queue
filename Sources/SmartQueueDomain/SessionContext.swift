import Foundation
import SmartQueueCore

/// Facts about the user's current listening period.
/// Recommendation policy and scoring stay outside this model.
public struct SessionContext: Sendable, Hashable {
    public let id: UUID
    public let startedAt: Date
    public let currentTrack: SessionTrackSnapshot?
    public let recentTracks: [SessionTrackSnapshot]
    public let queue: [SessionTrackSnapshot]

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        currentTrack: SessionTrackSnapshot? = nil,
        recentTracks: [SessionTrackSnapshot] = [],
        queue: [SessionTrackSnapshot] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.currentTrack = currentTrack
        self.recentTracks = recentTracks
        self.queue = queue
    }

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
