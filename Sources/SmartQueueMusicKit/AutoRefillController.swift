import Foundation
import SmartQueueCore

@MainActor
public final class AutoRefillController {
    private let coordinator: SmartQueueCoordinator
    private let policy: QueuePolicy

    public private(set) var isEnabled = false
    public private(set) var isRefilling = false
    public private(set) var lastErrorDescription: String?

    public init(
        coordinator: SmartQueueCoordinator,
        policy: QueuePolicy = QueuePolicy()
    ) {
        self.coordinator = coordinator
        self.policy = policy
    }

    public func start() {
        isEnabled = true
        lastErrorDescription = nil
    }

    public func stop() {
        isEnabled = false
    }

    /// Call this whenever the host app receives a queue/playback-state update.
    /// If the remaining queue is at or below the threshold, a new batch is planned
    /// and appended. The controller never calls play itself.
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
        lastErrorDescription = nil
        defer { isRefilling = false }

        do {
            let batch = try await coordinator.makeNextBatch(
                current: current,
                activeQueueTrackIDs: activeQueueTrackIDs,
                recentArtistNames: recentArtistNames
            )
            guard !batch.isEmpty else { return }
            try await coordinator.appendBatch(batch)
        } catch {
            // Preserve the error for the host UI/logging layer instead of silently
            // converting an Apple Music or network failure into a no-op.
            lastErrorDescription = String(describing: error)
        }
    }
}
