import Foundation
import MusicKit

public enum MusicAuthorizationState: Sendable, Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized
    case unknown
}

@MainActor
public final class MusicAuthorizationService {
    public init() {}

    public func requestAuthorization() async -> MusicAuthorizationState {
        let status = await MusicAuthorization.request()
        return Self.map(status)
    }

    public func currentState() -> MusicAuthorizationState {
        Self.map(MusicAuthorization.currentStatus)
    }

    private static func map(_ status: MusicAuthorization.Status) -> MusicAuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized:
            return .authorized
        @unknown default:
            return .unknown
        }
    }
}
