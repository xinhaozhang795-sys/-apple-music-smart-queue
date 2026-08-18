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
        self.position = Self.nonNegativeFinite(position)
        self.duration = duration.map(Self.nonNegativeFinite)
        self.isPlaying = isPlaying
    }

    private static func nonNegativeFinite(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

/// Capabilities reported by a platform playback implementation.
///
/// Capability values describe platform/API support. They do not guarantee that
/// a transition will be applied for every pair of tracks or playback scenario.
public struct PlaybackCapabilities: Sendable, Equatable {
    public let canSeek: Bool
    public let canPreloadNext: Bool
    public let canCrossfade: Bool
    /// A platform-declared maximum duration, when one is known.
    /// `nil` means the platform does not expose a known maximum through this abstraction.
    public let maxCrossfadeDuration: TimeInterval?

    public init(
        canSeek: Bool,
        canPreloadNext: Bool,
        canCrossfade: Bool,
        maxCrossfadeDuration: TimeInterval? = nil
    ) {
        self.canSeek = canSeek
        self.canPreloadNext = canPreloadNext
        self.canCrossfade = canCrossfade
        self.maxCrossfadeDuration = maxCrossfadeDuration.map(Self.nonNegativeFinite)
    }

    private static func nonNegativeFinite(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

/// Playback transition requested by the queue engine.
public struct PlaybackTransition: Sendable, Equatable {
    public let duration: TimeInterval
    public let reason: TransitionReason

    public init(duration: TimeInterval, reason: TransitionReason) {
        self.duration = Self.nonNegativeFinite(duration)
        self.reason = reason
    }

    private static func nonNegativeFinite(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite else { return 0 }
        return max(0, value)
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
