import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackMonitor {
    private struct PlaybackSession {
        let trackID: MusicItemID
        let startedAt: Date
        var lastObservedTime: TimeInterval
        var reachedEnd: Bool

        init(trackID: MusicItemID, startedAt: Date, initialTime: TimeInterval) {
            self.trackID = trackID
            self.startedAt = startedAt
            self.lastObservedTime = max(0, initialTime)
            self.reachedEnd = false
        }
    }

    private let player = SystemMusicPlayer.shared
    private var task: Task<Void, Never>?
    private var lastTrackID: MusicItemID?
    private var lastPlaybackStatus: MusicPlayer.PlaybackStatus?
    private var session: PlaybackSession?
    private var lastCompletedTrackID: MusicItemID?
    private let memoryLimit: Int

    public private(set) var currentTrackID: MusicItemID?
    public private(set) var playbackStatus: MusicPlayer.PlaybackStatus = .stopped
    public private(set) var playbackTime: TimeInterval = 0
    public private(set) var listeningMemory: ListeningMemory

    public init(listeningMemory: ListeningMemory = ListeningMemory(), memoryLimit: Int = 500) {
        self.listeningMemory = listeningMemory
        self.memoryLimit = max(1, memoryLimit)
    }

    public func start(onChange: @escaping @MainActor (_ trackID: MusicItemID?, _ status: MusicPlayer.PlaybackStatus) -> Void) {
        stop()
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let trackID = self.player.queue.currentEntry.map { MusicItemID(rawValue: $0.id) }
                let status = self.player.state.playbackStatus
                let rawTime = self.player.playbackTime
                let time = rawTime.isFinite && rawTime >= 0 ? rawTime : 0
                let changed = trackID != self.lastTrackID || status != self.lastPlaybackStatus

                self.currentTrackID = trackID
                self.playbackStatus = status
                self.playbackTime = time
                self.observe(trackID: trackID, status: status, time: time)

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
        finishActiveSession()
    }

    private func observe(trackID: MusicItemID?, status: MusicPlayer.PlaybackStatus, time: TimeInterval) {
        if let active = session, active.trackID != trackID {
            finishActiveSession()
        }

        guard let trackID, status == .playing else { return }

        if session == nil || session?.trackID != trackID {
            let now = Date()
            session = PlaybackSession(trackID: trackID, startedAt: now, initialTime: time)
            appendEvent(
                ListeningEvent(
                    trackID: trackID.rawValue,
                    timestamp: now,
                    outcome: .started
                )
            )
            return
        }

        guard var active = session else { return }

        // Keep the last valid playhead for the active track. This value is used
        // when the next track appears, so the previous track never receives the
        // new track's near-zero playback time.
        if time > active.lastObservedTime + 0.25 {
            active.lastObservedTime = time
        }

        // A substantial forward position followed by a reset is a useful end
        // marker. It is deliberately conservative because MusicKit does not
        // expose duration through this monitor.
        if time < active.lastObservedTime * 0.25 && active.lastObservedTime > 30 {
            active.reachedEnd = true
        }
        session = active
    }

    private func finishActiveSession() {
        guard let active = session else { return }
        session = nil

        let finalOutcome: ListeningEvent.Outcome = active.reachedEnd ? .completed : .skipped

        if finalOutcome == .completed && lastCompletedTrackID == active.trackID {
            return
        }
        if finalOutcome == .completed {
            lastCompletedTrackID = active.trackID
        }

        appendEvent(
            ListeningEvent(
                trackID: active.trackID.rawValue,
                timestamp: Date(),
                progress: active.lastObservedTime > 0 ? active.lastObservedTime : nil,
                outcome: finalOutcome
            )
        )
    }

    private func appendEvent(_ event: ListeningEvent) {
        listeningMemory = listeningMemory.appending(event, limit: memoryLimit)
    }

    deinit {
        task?.cancel()
    }
}
