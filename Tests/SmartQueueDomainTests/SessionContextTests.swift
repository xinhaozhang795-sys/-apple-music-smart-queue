import XCTest
@testable import SmartQueueDomain

final class SessionContextTests: XCTestCase {
    func testSessionPreservesCurrentRecentAndQueueContext() {
        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist"
        )
        let recent = SessionTrackSnapshot(
            trackID: "recent",
            title: "Recent",
            artistName: "Artist B"
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
            recentTracks: [recent],
            queue: [queued]
        )

        XCTAssertEqual(session.currentTrack?.trackID, "current")
        XCTAssertEqual(session.recentTracks.map(\.trackID), ["recent"])
        XCTAssertTrue(session.contains(trackID: "queued"))
        XCTAssertFalse(session.contains(trackID: "missing"))
    }

    func testSessionIdentityAndStartTimeAreStable() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 123)
        let session = SessionContext(id: id, startedAt: start)

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.startedAt, start)
    }
}
