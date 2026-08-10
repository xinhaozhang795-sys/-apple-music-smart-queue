import Foundation
import SmartQueueCore

@MainActor
public final class AutoRefillController {
    private let coordinator: SmartQueueCoordinator
    private let policy: QueuePolicy

    public private(set) var isEnabled = false
    public private(set) var isRefilling = false

    public init(
        coordinator: SmartQueueCoordinator,
        policy: QueuePolicy = QueuePolicy()
    ) {
        self.coordinator = coordinator
        self.policy = policy
    }

    public func start() {
        isEnabled = true
    }

    public func stop() {
        isEnabled = false
    }

    /// Call this whenever the host app receives a queue/playback-state update.
    /// If the remaining queue is at or below the threshold, a new batch is planned
    /// and loaded. The controller never calls play itself.
    public func handleQueueCount(
        _ remainingCount: Int,
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String> = [],
        recentArtistNames: Set<String> = []
    ) async {
        guard isEnabled,
              !isRefilling,
              remainingCount <= policy.refillThreshold else { return }

        isRefilling = true
        defer { isRefilling = false }

        do {
            let batch = try await coordinator.makeNextBatch(
                current: current,
                activeQueueTrackIDs: activeQueueTrackIDs,
                recentArtistNames: recentArtistNames
            )
            guard !batch.isEmpty else { return }
            try await coordinator.loadBatch(batch, play: false)
        } catch {
            // The host app can surface the error and retry on the next state update.
        }
    }
}
