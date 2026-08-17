import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackMonitor {
    private let player = SystemMusicPlayer.shared
    private var task: Task<Void, Never>?
    private var lastTrackID: MusicItemID?
    private var lastPlaybackStatus: MusicPlayer.PlaybackStatus?
    private var lastEventTrackID: MusicItemID?
    private var lastEventTimestamp: Date?
    private let memoryLimit: Int

    public private(set) var currentTrackID: MusicItemID?
    public private(set) var playbackStatus: MusicPlayer.PlaybackStatus = .stopped
    public private(set) var listeningMemory: ListeningMemory

    public init(listeningMemory: ListeningMemory = ListeningMemory(), memoryLimit: Int = 500) {
        self.listeningMemory = listeningMemory
        self.memoryLimit = max(1, memoryLimit)
    }

    /// Starts a lightweight polling loop. Playback changes are recorded as
    /// listening events and also exposed to the host for queue refill decisions.
    public func start(onChange: @escaping @MainActor (_ trackID: MusicItemID?, _ status: MusicPlayer.PlaybackStatus) -> Void) {
        stop()
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let trackID: MusicItemID?
                if let rawTrackID = self.player.queue.currentEntry?.id {
                    trackID = MusicItemID(rawValue: rawTrackID)
                } else {
                    trackID = nil
                }

                let status = self.player.state.playbackStatus
                let changed = trackID != self.lastTrackID || status != self.lastPlaybackStatus

                self.currentTrackID = trackID
                self.playbackStatus = status

                if changed {
                    self.recordTransition(to: trackID, status: status)
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

    private func recordTransition(to trackID: MusicItemID?, status: MusicPlayer.PlaybackStatus) {
        guard let trackID else { return }
        let now = Date()

        if status == .playing {
            let isReplay = lastEventTrackID == trackID
            let outcome: ListeningEvent.Outcome = isReplay ? .replayed : .started
            appendEvent(ListeningEvent(trackID: trackID.rawValue, timestamp: now, outcome: outcome))
            lastEventTrackID = trackID
            lastEventTimestamp = now
        } else if status == .paused, let previousTrack = lastEventTrackID, previousTrack != trackID {
            appendEvent(ListeningEvent(trackID: previousTrack.rawValue, timestamp: now, outcome: .skipped))
        }
    }

    private func appendEvent(_ event: ListeningEvent) {
        listeningMemory = listeningMemory.appending(event, limit: memoryLimit)
    }

    deinit {
        task?.cancel()
    }
}
