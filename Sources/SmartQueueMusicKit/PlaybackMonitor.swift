import Foundation
import MusicKit

@MainActor
public final class PlaybackMonitor {
    private let player = SystemMusicPlayer.shared
    private var task: Task<Void, Never>?
    private var lastTrackID: MusicItemID?
    private var lastPlaybackStatus: MusicPlayer.PlaybackStatus?

    public private(set) var currentTrackID: MusicItemID?
    public private(set) var playbackStatus: MusicPlayer.PlaybackStatus = .stopped

    public init() {}

    /// Starts a lightweight polling loop. The host app can use `onChange` to
    /// trigger AutoRefillController when playback context changes.
    public func start(onChange: @escaping @MainActor (_ trackID: MusicItemID?, _ status: MusicPlayer.PlaybackStatus) -> Void) {
        stop()
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let trackID = self.player.queue.currentEntry?.id.map { MusicItemID(rawValue: $0) }
                let status = self.player.state.playbackStatus
                let changed = trackID != self.lastTrackID || status != self.lastPlaybackStatus

                self.currentTrackID = trackID
                self.playbackStatus = status

                if changed {
                    self.lastTrackID = trackID
                    self.lastPlaybackStatus = status
                    onChange(trackID, status)
                }

                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }
}
