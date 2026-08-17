import Foundation

public struct QueuePlanner: Sendable {
    public let scoringEngine: ScoringEngine
    public let sequencePlanner: QueueSequencePlanner
    public let policy: QueuePolicy

    public init(policy: QueuePolicy = QueuePolicy()) {
        self.policy = policy
        self.scoringEngine = ScoringEngine(policy: policy)
        self.sequencePlanner = QueueSequencePlanner()
    }

    public func plan(
        candidates: [TrackCandidate],
        current: CurrentTrackContext,
        activeQueueTrackIDs: Set<String> = [],
        recentArtistNames: Set<String> = []
    ) -> [ScoredCandidate] {
        let ranked = scoringEngine.rank(
            candidates.filter { $0.id != current.trackID },
            current: current,
            activeQueueTrackIDs: activeQueueTrackIDs,
            recentArtistNames: recentArtistNames
        )

        var selected: [ScoredCandidate] = []
        selected.reserveCapacity(policy.refillBatchSize)

        var selectedIDs = activeQueueTrackIDs
        selectedIDs.reserveCapacity(activeQueueTrackIDs.count + policy.refillBatchSize)

        var selectedArtists = recentArtistNames
        selectedArtists.reserveCapacity(recentArtistNames.count + policy.refillBatchSize)

        for candidate in ranked {
            guard selected.count < policy.refillBatchSize else { break }
            guard !selectedIDs.contains(candidate.id) else { continue }
            guard !selectedArtists.contains(candidate.candidate.artistName) else { continue }

            selected.append(candidate)
            selectedIDs.insert(candidate.id)
            selectedArtists.insert(candidate.candidate.artistName)
        }

        if selected.count < policy.refillBatchSize {
            for candidate in ranked {
                guard selected.count < policy.refillBatchSize else { break }
                guard !selectedIDs.contains(candidate.id) else { continue }

                selected.append(candidate)
                selectedIDs.insert(candidate.id)
            }
        }

        return sequencePlanner.plan(
            candidates: selected,
            current: current,
            limit: selected.count
        )
    }
}
