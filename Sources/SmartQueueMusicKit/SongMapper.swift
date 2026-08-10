import Foundation
import MusicKit
import SmartQueueCore

public struct SongMapper: Sendable {
    public init() {}

    public func map(_ song: Song, source: CandidateSource = .discovery) -> TrackCandidate {
        TrackCandidate(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            source: source,
            affinity: 0,
            continuity: 0,
            freshness: freshness(for: song.lastPlayedDate)
        )
    }

    private func freshness(for date: Date?) -> Double {
        guard let date else { return 1.0 }
        let days = max(0, Date().timeIntervalSince(date) / 86_400)
        return min(days / 30.0, 1.0)
    }
}
