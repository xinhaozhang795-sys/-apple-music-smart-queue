import Foundation

/// Platform-neutral source of music candidates.
///
/// iOS and Android provide their own adapters while the recommendation and
/// queue-planning engine remains shared.
public protocol MusicCandidateSource: Sendable {
    func personalRecommendations() async throws -> [TrackCandidate]
    func recentlyPlayed() async throws -> [TrackCandidate]
}

/// Platform-neutral playback surface used by the Smart Queue engine.
///
/// Platform adapters own the actual Apple Music player integration. The core
/// engine only asks for state and queue operations.
@MainActor
public protocol MusicPlaybackAdapter: AnyObject {
    var currentTrackID: String? { get }
    var isPlaying: Bool { get }

    func setQueue(trackIDs: [String], play: Bool) async throws
    func play() async throws
    func pause()
}
