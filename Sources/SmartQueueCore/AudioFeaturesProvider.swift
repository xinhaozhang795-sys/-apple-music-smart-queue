import Foundation

/// Supplies normalized audio features to the recommendation engine.
///
/// The core layer deliberately knows nothing about the source of the analysis.
/// An iOS adapter may use Music Understanding, while other platforms may use a
/// different implementation or return nil when analysis is unavailable.
public protocol AudioFeaturesProvider: Sendable {
    func features(for trackID: String) async throws -> AudioFeatures?
}

public struct NullAudioFeaturesProvider: AudioFeaturesProvider {
    public init() {}

    public func features(for trackID: String) async throws -> AudioFeatures? {
        nil
    }
}
