import Foundation
import SmartQueueCore

@available(iOS 18.0, *)
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

    /// Plans and appends a new batch when the remaining queue reaches the refill threshold.
    /// The same operation computes and applies the transition policy for the
    /// current-track -> next-track edge before mutating the queue.
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
            try await coordinator.appendBatch(batch, current: current)
        } catch {
            lastErrorDescription = String(describing: error)
        }
    }
}
