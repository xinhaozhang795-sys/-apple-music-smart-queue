import XCTest
@testable import SmartQueueCore

final class ScoringEngineTests: XCTestCase {
    func testRanksPersonalRecommendationWithAffinity() {
        let engine = ScoringEngine()
        let current = CurrentTrackContext(trackID: "current", title: "Current", artistName: "Artist A")

        let recommended = TrackCandidate(
            id: "recommended",
            title: "Recommended",
            artistName: "Artist B",
            source: .personalRecommendation,
            affinity: 0.8,
            continuity: 0.8,
            freshness: 0.8
        )

        let library = TrackCandidate(
            id: "library",
            title: "Library",
            artistName: "Artist C",
            source: .library,
            affinity: 0.8,
            continuity: 0.8,
            freshness: 0.8
        )

        let ranked = engine.rank(
            [library, recommended],
            current: current,
            activeQueueTrackIDs: [],
            recentArtistNames: []
        )

        XCTAssertEqual(ranked.first?.id, "recommended")
    }

    func testPenalizesRecentArtist() {
        let engine = ScoringEngine()
        let current = CurrentTrackContext(trackID: "current", title: "Current", artistName: "Artist A")

        let repeated = TrackCandidate(
            id: "repeated",
            title: "Repeated",
            artistName: "Artist B",
            source: .library,
            affinity: 0.8,
            continuity: 0.8,
            freshness: 0.8
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

        let ranked = engine.rank(
            [repeated, freshArtist],
            current: current,
            activeQueueTrackIDs: [],
            recentArtistNames: ["Artist B"]
        )

        XCTAssertEqual(ranked.first?.id, "fresh")
    }

    func testPenalizesDuplicateAlreadyInQueue() {
        let engine = ScoringEngine()
        let current = CurrentTrackContext(trackID: "current", title: "Current", artistName: "Artist A")

        let duplicate = TrackCandidate(
            id: "duplicate",
            title: "Duplicate",
            artistName: "Artist B",
            source: .library,
            affinity: 0.8,
            continuity: 0.8,
            freshness: 0.8
        )

        let other = TrackCandidate(
            id: "other",
            title: "Other",
            artistName: "Artist C",
            source: .library,
            affinity: 0.8,
            continuity: 0.8,
            freshness: 0.8
        )

        let ranked = engine.rank(
            [duplicate, other],
            current: current,
            activeQueueTrackIDs: ["duplicate"],
            recentArtistNames: []
        )

        XCTAssertEqual(ranked.first?.id, "other")
    }
}
