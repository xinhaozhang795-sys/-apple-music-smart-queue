import Foundation
import MusicKit

@MainActor
final class AppleMusicAuthorization: ObservableObject {
    @Published private(set) var status: MusicAuthorization.Status = .notDetermined

    func refresh() {
        status = MusicAuthorization.currentStatus
    }

    func request() async {
        status = await MusicAuthorization.request()
    }

    var isAuthorized: Bool {
        status == .authorized
    }
}
