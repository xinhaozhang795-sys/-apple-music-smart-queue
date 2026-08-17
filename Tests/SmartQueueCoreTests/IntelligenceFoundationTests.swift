import XCTest
@testable import SmartQueueCore

final class IntelligenceFoundationTests: XCTestCase {
    func testListeningMemoryKeepsNewestEvents() {
        let first = ListeningEvent(trackID: "a", outcome: .started)
        let second = ListeningEvent(trackID: "b", outcome: .completed)
        let memory = ListeningMemory(events: [first]).appending(second, limit: 1)

        XCTAssertEqual(memory.events.map(\.trackID), ["b"])
        XCTAssertEqual(memory.completionCount(for: "b"), 1)
    }

    func testListeningEventDerivesNormalizedProgressFromDuration() {
        let event = ListeningEvent(
            trackID: "track",
            elapsedTime: 90,
            duration: 180,
            outcome: .skipped
        )

        XCTAssertNotNil(event.progress)
        XCTAssertEqual(event.progress ?? 0, 0.5, accuracy: 0.0001)
    }

    func testListeningEventClampsProgressAndDurationInputs() {
        let event = ListeningEvent(
            trackID: "track",
            elapsedTime: -10,
            duration: -1,
            progress: 2,
            outcome: .started
        )

        XCTAssertEqual(event.elapsedTime, 0)
        XCTAssertEqual(event.duration, 0)
        XCTAssertEqual(event.progress, 1)
    }

    func testTasteProfileLearnsTowardObservedFeatures() {
        let profile = TasteProfile()
        let features = AudioFeatures(energy: 1, danceability: 1, valence: 0)
        let updated = profile.updated(with: features, signal: 1, learningRate: 0.5)

        XCTAssertEqual(updated.preferredEnergy, 0.75, accuracy: 0.0001)
        XCTAssertEqual(updated.preferredDanceability, 0.75, accuracy: 0.0001)
        XCTAssertEqual(updated.preferredValence, 0.25, accuracy: 0.0001)
    }

    func testFatiguePenalizesRecentTrackMoreThanArtistOrGenre() {
        let state = FatigueState(
            recentTrackIDs: ["track"],
            recentArtistIDs: ["artist"],
            recentGenreKeys: ["pop"]
        )

        XCTAssertEqual(state.penalty(trackID: "track", artistID: "artist", genreKey: "pop"), 1)
        XCTAssertEqual(state.penalty(trackID: "other", artistID: "artist", genreKey: "pop"), 0.75, accuracy: 0.0001)
        XCTAssertEqual(state.penalty(trackID: "other", artistID: nil, genreKey: "pop"), 0.2, accuracy: 0.0001)
    }
}
