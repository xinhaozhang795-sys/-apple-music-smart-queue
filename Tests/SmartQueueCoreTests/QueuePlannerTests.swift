import XCTest
@testable import SmartQueueCore

final class QueuePlannerTests: XCTestCase {
    func testFirstPassAvoidsArtistRepeatsIgnoringCaseAndWhitespace() {
        let policy = QueuePolicy(refillBatchSize: 2)
        let planner = QueuePlanner(policy: policy)
        let current = CurrentTrackContext(trackID: "current", title: "Current", artistName: "Artist A")

        let repeatedArtist = TrackCandidate(
            id: "repeat",
            title: "Repeat",
            artistName: " artist b ",
            source: .personalRecommendation,
            affinity: 1.0,
            continuity: 1.0,
            freshness: 1.0
        )

        let freshArtist = TrackCandidate(
            id: "fresh",
            title: "Fresh",
            artistName: "Artist C",
            source: .library,
            affinity: 0.8,
            continuity: 0.8,
            freshness: 0.8
        )

        let planned = planner.plan(
            candidates: [repeatedArtist, freshArtist],
            current: current,
            recentArtistNames: ["ARTIST B"]
        )

        XCTAssertEqual(planned.first?.id, "fresh")
    }
}
