import Foundation

/// Platform-neutral playback state exposed to SmartQueueCore.
public struct PlaybackState: Sendable, Equatable {
    public let trackID: String?
    public let position: TimeInterval
    public let duration: TimeInterval?
    public let isPlaying: Bool

    public init(
        trackID: String?,
        position: TimeInterval,
        duration: TimeInterval?,
        isPlaying: Bool
    ) {
        self.trackID = trackID
        self.position = max(0, position)
        self.duration = duration.map { max(0, $0) }
        self.isPlaying = isPlaying
    }
}

/// Capabilities reported by a platform playback implementation.
public struct PlaybackCapabilities: Sendable, Equatable {
    public let canSeek: Bool
    public let canPreloadNext: Bool
    public let canCrossfade: Bool
    public let maxCrossfadeDuration: TimeInterval

    public init(
        canSeek: Bool,
        canPreloadNext: Bool,
        canCrossfade: Bool,
        maxCrossfadeDuration: TimeInterval
    ) {
        self.canSeek = canSeek
        self.canPreloadNext = canPreloadNext
        self.canCrossfade = canCrossfade
        self.maxCrossfadeDuration = max(0, maxCrossfadeDuration)
    }
}

/// Playback transition requested by the queue engine.
public struct PlaybackTransition: Sendable, Equatable {
    public let duration: TimeInterval
    public let reason: TransitionReason

    public init(duration: TimeInterval, reason: TransitionReason) {
        self.duration = max(0, duration)
        self.reason = reason
    }
}

public enum TransitionReason: Sendable, Equatable {
    case crossfade
    case gapless
    case hardCut
}

/// Minimal contract implemented by every platform-specific playback adapter.
public protocol PlaybackEngine: Sendable {
    var capabilities: PlaybackCapabilities { get }
    var state: PlaybackState { get }

    func play() async throws
    func pause() async throws
    func skipNext() async throws
    func skipPrevious() async throws
    func seek(to position: TimeInterval) async throws
}

/// Optional capability for platforms that can explicitly preload the next track.
public protocol PlaybackPreloading: PlaybackEngine {
    func preloadNext(trackID: String) async throws
}

/// Optional capability for platforms that can explicitly control transitions.
public protocol PlaybackTransitionControlling: PlaybackEngine {
    func apply(transition: PlaybackTransition) async throws
}
