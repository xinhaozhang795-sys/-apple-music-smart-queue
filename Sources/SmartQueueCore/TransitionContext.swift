import Foundation

/// Immutable context used to evaluate how naturally one track can follow another.
public struct TransitionContext: Sendable, Equatable {
    public let current: AudioFeatures?
    public let candidate: AudioFeatures?

    public init(current: AudioFeatures? = nil, candidate: AudioFeatures? = nil) {
        self.current = current
        self.candidate = candidate
    }
}
