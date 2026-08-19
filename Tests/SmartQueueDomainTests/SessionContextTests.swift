import XCTest
@testable import SmartQueueDomain

final class SessionContextTests: XCTestCase {
    func testSessionPreservesCurrentQueueContext() {
        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist"
        )
        let queued = SessionTrackSnapshot(
            trackID: "queued",
            title: "Queued",
            artistName: "Other",
            position: 2
        )

        let session = SessionContext(
            startedAt: Date(timeIntervalSince1970: 100),
            currentTrack: SessionTrackSnapshot(current),
            queue: [queued]
        )

        XCTAssertEqual(session.currentTrack?.trackID, "current")
        XCTAssertTrue(session.contains(trackID: "queued"))
        XCTAssertFalse(session.contains(trackID: "missing"))
    }

    func testMoodAndExplorationValuesAreBounded() {
        let mood = SessionMood(valence: -1, energy: 2, danceability: 0.5, confidence: 4)
        let exploration = SessionExplorationState(openness: -1, successfulDiscoveries: -2, rejectedDiscoveries: 3)

        XCTAssertEqual(mood.valence, 0)
        XCTAssertEqual(mood.energy, 1)
        XCTAssertEqual(mood.confidence, 1)
        XCTAssertEqual(exploration.openness, 0)
        XCTAssertEqual(exploration.successfulDiscoveries, 0)
        XCTAssertEqual(exploration.rejectedDiscoveries, 3)
    }

    func testSessionIdentityAndStartTimeAreStable() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 123)
        let session = SessionContext(id: id, startedAt: start)

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.startedAt, start)
    }
}
