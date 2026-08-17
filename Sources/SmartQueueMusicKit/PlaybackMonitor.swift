import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackMonitor {
    private struct PlaybackSession {
        let trackID: MusicItemID
        let startedAt: Date
        let duration: TimeInterval?
        var lastObservedTime: TimeInterval

        init(trackID: MusicItemID, startedAt: Date, duration: TimeInterval?, initialTime: TimeInterval) {
            self.trackID = trackID
            self.startedAt = startedAt
            self.duration = duration
            self.lastObservedTime = max(0, initialTime)
        }
    }

    private let player = SystemMusicPlayer.shared
    private var task: Task<Void, Never>?
    private var lastTrackID: MusicItemID?
    private var lastPlaybackStatus: MusicPlayer.PlaybackStatus?
    private var session: PlaybackSession?
    private var lastFinishedTrackID: MusicItemID?
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
                let entry = self.player.queue.currentEntry
                let trackID = entry.map { MusicItemID(rawValue: $0.id) }
                let status = self.player.state.playbackStatus
                let rawTime = self.player.playbackTime
                let time = rawTime.isFinite && rawTime >= 0 ? rawTime : 0
                let duration = Self.duration(for: entry)
                let changed = trackID != self.lastTrackID || status != self.lastPlaybackStatus

                self.currentTrackID = trackID
                self.playbackStatus = status
                self.playbackTime = time
                self.observe(trackID: trackID, status: status, time: time, duration: duration)

                if changed {
                    self.lastTrackID = trackID
                    self.lastPlaybackStatus = status
                    onChange(trackID, status)
                }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
        finishActiveSession(forceOutcome: .skipped)
    }

    private func observe(trackID: MusicItemID?, status: MusicPlayer.PlaybackStatus, time: TimeInterval, duration: TimeInterval?) {
        if let active = session, active.trackID != trackID {
            finishActiveSession(forceOutcome: nil)
        }

        if let active = session, status == .stopped {
            finishActiveSession(forceOutcome: isNearEnd(active) ? .completed : .skipped)
            return
        }

        guard let trackID, status == .playing else { return }

        if session == nil || session?.trackID != trackID {
            let now = Date()
            let outcome: ListeningEvent.Outcome = lastFinishedTrackID == trackID ? .replayed : .started
            session = PlaybackSession(trackID: trackID, startedAt: now, duration: duration, initialTime: time)
            appendEvent(ListeningEvent(trackID: trackID.rawValue, timestamp: now, elapsedTime: time, duration: duration, outcome: outcome))
            return
        }

        guard var active = session else { return }
        // Only advance the high-water mark. Seeking backward must never erase
        // the trustworthy progress that will be used when this session ends.
        if time > active.lastObservedTime + 0.25 {
            active.lastObservedTime = time
        }
        session = active
    }

    private func finishActiveSession(forceOutcome: ListeningEvent.Outcome?) {
        guard let active = session else { return }
        session = nil
        let outcome = forceOutcome ?? (isNearEnd(active) ? .completed : .skipped)
        lastFinishedTrackID = active.trackID
        appendEvent(ListeningEvent(trackID: active.trackID.rawValue, timestamp: Date(), elapsedTime: active.lastObservedTime, duration: active.duration, outcome: outcome))
    }

    private func isNearEnd(_ session: PlaybackSession) -> Bool {
        guard let duration = session.duration, duration > 0 else { return false }
        let remaining = duration - session.lastObservedTime
        return remaining >= 0 && remaining <= max(2.0, duration * 0.03)
    }

    private static func duration(for entry: MusicPlayer.Queue.Entry?) -> TimeInterval? {
        guard let entry else { return nil }
        if let endTime = entry.endTime, let startTime = entry.startTime, endTime > startTime {
            return endTime - startTime
        }
        if case let .song(song) = entry.item, let duration = song.duration, duration > 0 {
            return duration
        }
        return nil
    }

    private func appendEvent(_ event: ListeningEvent) {
        listeningMemory = listeningMemory.appending(event, limit: memoryLimit)
    }

    deinit {
        task?.cancel()
    }
}
