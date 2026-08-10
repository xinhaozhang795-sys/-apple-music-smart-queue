import Foundation
import MusicKit
import SmartQueueCore

public struct SongMapper: Sendable {
    public init() {}

    public func map(_ song: Song) -> TrackCandidate {
        TrackCandidate(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            genreNames: song.genreNames,
            duration: song.duration,
            lastPlayedDate: song.lastPlayedDate,
            isExplicit: song.contentRating != nil,
            audioFeatures: nil
        )
    }
}
