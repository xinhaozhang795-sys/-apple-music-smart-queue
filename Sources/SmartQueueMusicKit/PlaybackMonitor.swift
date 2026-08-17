import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackMonitor {
    private struct PlaybackSession {
        let trackID: MusicItemID
        let startedAt: Date
        var lastObservedTime: TimeInterval
        var lastProgressAt: Date
        var reachedEnd: Bool

        init(trackID: MusicItemID, startedAt: Date, initialTime: TimeInterval) {
            self.trackID = trackID
            self.startedAt = startedAt
            self.lastObservedTime = max(0, initialTime)
            self.lastProgressAt = startedAt
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
        finishActiveSession(as: .neutral)
    }

    private func observe(trackID: MusicItemID?, status: MusicPlayer.PlaybackStatus, time: TimeInterval) {
        let now = Date()

        if let active = session, active.trackID != trackID {
            finishActiveSession(as: completionOutcome(for: active))
        }

        guard let trackID, status == .playing else {
            return
        }

        if session == nil || session?.trackID != trackID {
            session = PlaybackSession(trackID: trackID, startedAt: now, initialTime: time)
            appendEvent(ListeningEvent(trackID: trackID.rawValue, timestamp: now, progress: normalizedProgress(time), outcome: .started))
            return
        }

        guard var active = session else { return }
        if time > active.lastObservedTime + 0.25 {
            active.lastObservedTime = time
            active.lastProgressAt = now
        }

        // MusicKit may report stopped/paused around the end of a track. A near-zero
        // playhead after substantial forward progress is treated as an end marker.
        if time < active.lastObservedTime * 0.25 && active.lastObservedTime > 30 {
            active.reachedEnd = true
        }
        session = active
    }

    private func finishActiveSession(as outcome: ListeningEvent.Outcome) {
        guard let active = session else { return }
        session = nil

        let progress = normalizedProgress(active.lastObservedTime)
        let finalOutcome: ListeningEvent.Outcome
        if active.reachedEnd || outcome == .completed {
            finalOutcome = .completed
        } else if outcome == .neutral {
            finalOutcome = .started
        } else {
            finalOutcome = .skipped
        }

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
                progress: progress,
                outcome: finalOutcome
            )
        )
    }

    private func completionOutcome(for active: PlaybackSession) -> ListeningEvent.Outcome {
        active.reachedEnd ? .completed : .skipped
    }

    private func normalizedProgress(_ time: TimeInterval) -> Double? {
        // Duration is intentionally not inferred here. Until a reliable duration
        // source is available, progress remains nil rather than pretending that
        // elapsed seconds equal completion percentage.
        time > 0 ? nil : nil
    }

    private func appendEvent(_ event: ListeningEvent) {
        listeningMemory = listeningMemory.appending(event, limit: memoryLimit)
    }

    deinit {
        task?.cancel()
    }
}
