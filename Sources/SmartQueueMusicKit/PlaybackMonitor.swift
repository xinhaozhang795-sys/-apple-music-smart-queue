import Foundation
import MusicKit
import SmartQueueCore

@MainActor
public final class PlaybackMonitor {
    private struct PlaybackSession {
        let trackID: MusicItemID
        let duration: TimeInterval?
        var lastObservedTime: TimeInterval

        init(trackID: MusicItemID, duration: TimeInterval?, initialTime: TimeInterval) {
            self.trackID = trackID
            self.duration = duration
            self.lastObservedTime = max(0, initialTime)
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
        task?.cancel()
        task = nil

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

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
                }
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
        // Monitoring lifecycle is not listening behavior. Keep the active
        // session so a later start() can continue it without fabricating skip.
    }

    private func observe(trackID: MusicItemID?, status: MusicPlayer.PlaybackStatus, time: TimeInterval, duration: TimeInterval?) {
        if let active = session, active.trackID != trackID {
            finishActiveSession()
        }

        if let active = session, status == .stopped {
            finishActiveSession(forceOutcome: isNearEnd(active) ? .completed : .skipped)
            return
        }

        guard let trackID, status == .playing else { return }

        if session == nil || session?.trackID != trackID {
            let now = Date()
            let outcome: ListeningEvent.Outcome = lastCompletedTrackID == trackID ? .replayed : .started
            session = PlaybackSession(trackID: trackID, duration: duration, initialTime: time)
            appendEvent(
                ListeningEvent(
                    trackID: trackID.rawValue,
                    timestamp: now,
                    elapsedTime: time,
                    duration: duration,
                    outcome: outcome
                )
            )
            return
        }

        guard var active = session else { return }
        if time > active.lastObservedTime + 0.25 {
            active.lastObservedTime = time
        }
        session = active
    }

    private func finishActiveSession(forceOutcome: ListeningEvent.Outcome? = nil) {
        guard let active = session else { return }
        session = nil

        let outcome = forceOutcome ?? (isNearEnd(active) ? .completed : .skipped)
        if outcome == .completed {
            lastCompletedTrackID = active.trackID
        }

        appendEvent(
            ListeningEvent(
                trackID: active.trackID.rawValue,
                timestamp: Date(),
                elapsedTime: active.lastObservedTime,
                duration: active.duration,
                outcome: outcome
            )
        )
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
