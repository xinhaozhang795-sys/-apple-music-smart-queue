import Foundation

/// Immutable listening event used as the foundation for adaptive queue decisions.
public struct ListeningEvent: Equatable, Sendable, Hashable {
    public enum Outcome: String, Sendable, Hashable {
        case started
        case completed
        case skipped
        case replayed
        case favorited
    }

    public let trackID: String
    public let artistID: String?
    public let albumID: String?
    public let timestamp: Date
    public let progress: Double?
    public let outcome: Outcome

    public init(
        trackID: String,
        artistID: String? = nil,
        albumID: String? = nil,
        timestamp: Date = .now,
        progress: Double? = nil,
        outcome: Outcome
    ) {
        self.trackID = trackID
        self.artistID = artistID
        self.albumID = albumID
        self.timestamp = timestamp
        self.progress = progress.map { min(1, max(0, $0)) }
        self.outcome = outcome
    }
}

/// A small, deterministic in-memory history. Persistence can be added later without
/// coupling the recommendation engine to a storage framework.
public struct ListeningMemory: Sendable {
    public let events: [ListeningEvent]

    public init(events: [ListeningEvent] = []) {
        self.events = events.sorted { $0.timestamp < $1.timestamp }
    }

    public func appending(_ event: ListeningEvent, limit: Int = 500) -> ListeningMemory {
        let boundedLimit = max(1, limit)
        let next = Array((events + [event]).suffix(boundedLimit))
        return ListeningMemory(events: next)
    }

    public func recentEvents(limit: Int = 50) -> [ListeningEvent] {
        Array(events.suffix(max(0, limit))).reversed()
    }

    public func recentTrackIDs(limit: Int = 20) -> Set<String> {
        Set(recentEvents(limit: limit).map(\.trackID))
    }

    public func recentArtistIDs(limit: Int = 20) -> Set<String> {
        Set(recentEvents(limit: limit).compactMap(\.artistID))
    }

    public func skipCount(for trackID: String) -> Int {
        events.filter { $0.trackID == trackID && $0.outcome == .skipped }.count
    }

    public func completionCount(for trackID: String) -> Int {
        events.filter { $0.trackID == trackID && $0.outcome == .completed }.count
    }
}
