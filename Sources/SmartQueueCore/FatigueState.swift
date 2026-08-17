import Foundation

/// Short-term repetition pressure used to prevent technically relevant but tiring queues.
public struct FatigueState: Equatable, Sendable {
    public let recentTrackIDs: Set<String>
    public let recentArtistIDs: Set<String>
    public let recentGenreKeys: Set<String>

    public init(
        recentTrackIDs: Set<String> = [],
        recentArtistIDs: Set<String> = [],
        recentGenreKeys: Set<String> = []
    ) {
        self.recentTrackIDs = recentTrackIDs
        self.recentArtistIDs = recentArtistIDs
        self.recentGenreKeys = recentGenreKeys
    }

    public func penalty(trackID: String, artistID: String?, genreKey: String?) -> Double {
        var penalty = 0.0
        if recentTrackIDs.contains(trackID) { penalty += 1.0 }
        if let artistID, recentArtistIDs.contains(artistID) { penalty += 0.55 }
        if let genreKey, recentGenreKeys.contains(genreKey) { penalty += 0.2 }
        return min(1, penalty)
    }
}
