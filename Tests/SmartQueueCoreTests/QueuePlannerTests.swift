import XCTest
@testable import SmartQueueCore

final class QueuePlannerTests: XCTestCase {
    func testExcludesCurrentTrackAndExistingQueueDuplicates() {
        let planner = QueuePlanner()
        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist A"
        )

        let candidates = [
            TrackCandidate(
                id: "current",
                title: "Current",
                artistName: "Artist A",
                source: .library,
                affinity: 1
            ),
            TrackCandidate(
                id: "existing",
                title: "Existing",
                artistName: "Artist B",
                source: .library,
                affinity: 1
            ),
            TrackCandidate(
                id: "new",
                title: "New",
                artistName: "Artist C",
                source: .library,
                affinity: 0.8
            )
        ]

        let result = planner.plan(
            candidates: candidates,
            current: current,
            activeQueueTrackIDs: ["existing"]
        )

        XCTAssertEqual(result.map(\.id), ["new"])
    }

    func testPrioritizesArtistDiversityBeforeRelaxingArtistConstraint() {
        let policy = QueuePolicy(refillBatchSize: 3)
        let planner = QueuePlanner(policy: policy)
        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist A"
        )

        let candidates = [
            TrackCandidate(id: "a1", title: "A1", artistName: "Artist B", source: .library, affinity: 1),
            TrackCandidate(id: "a2", title: "A2", artistName: "Artist B", source: .library, affinity: 0.9),
            TrackCandidate(id: "c1", title: "C1", artistName: "Artist C", source: .library, affinity: 0.8),
            TrackCandidate(id: "d1", title: "D1", artistName: "Artist D", source: .library, affinity: 0.7)
        ]

        let result = planner.plan(candidates: candidates, current: current)

        XCTAssertEqual(result.map(\.id), ["a1", "c1", "d1"])
        XCTAssertEqual(Set(result.map { $0.candidate.artistName }).count, 3)
    }

    func testRelaxesArtistConstraintWhenThereAreNotEnoughArtists() {
        let policy = QueuePolicy(refillBatchSize: 3)
        let planner = QueuePlanner(policy: policy)
        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist A"
        )

        let candidates = [
            TrackCandidate(id: "a1", title: "A1", artistName: "Artist B", source: .library, affinity: 1),
            TrackCandidate(id: "a2", title: "A2", artistName: "Artist B", source: .library, affinity: 0.9)
        ]

        let result = planner.plan(candidates: candidates, current: current)

        XCTAssertEqual(result.map(\.id), ["a1", "a2"])
    }

    func testDoesNotReturnDuplicateCandidateIDs() {
        let policy = QueuePolicy(refillBatchSize: 4)
        let planner = QueuePlanner(policy: policy)
        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist A"
        )

        let candidates = [
            TrackCandidate(id: "same", title: "Same", artistName: "Artist B", source: .library, affinity: 1),
            TrackCandidate(id: "same", title: "Same Duplicate", artistName: "Artist C", source: .library, affinity: 0.5),
            TrackCandidate(id: "other", title: "Other", artistName: "Artist D", source: .library, affinity: 0.4)
        ]

        let result = planner.plan(candidates: candidates, current: current)

        XCTAssertEqual(result.map(\.id), ["same", "other"])
        XCTAssertEqual(Set(result.map(\.id)).count, result.count)
    }
}
