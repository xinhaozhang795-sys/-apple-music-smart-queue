import XCTest
@testable import SmartQueueIntelligence
import SmartQueueCore
import SmartQueueDomain

final class ContextualCandidateEvaluatorTests: XCTestCase {
    func testStrongContextFitProducesInsert() {
        let session = SessionContext(
            startedAt: Date(timeIntervalSince1970: 1),
            currentTrack: SessionTrackSnapshot(
                trackID: "current",
                title: "Current",
                artistName: "Artist"
            ),
            mood: SessionMood(valence: 0.8, energy: 0.8, danceability: 0.7, confidence: 1)
        )
        let candidate = TrackCandidate(
            id: "candidate",
            title: "Candidate",
            artistName: "Other",
            source: .personalRecommendation,
            affinity: 0.95,
            freshness: 0.8
        )
        let current = AudioFeatures(bpm: 120, energy: 0.8, danceability: 0.7, valence: 0.8)
        let features = AudioFeatures(bpm: 122, energy: 0.82, danceability: 0.68, valence: 0.78)

        let decision = ContextualCandidateEvaluator().evaluate(
            candidate: candidate,
            candidateFeatures: features,
            currentFeatures: current,
            session: session
        )

        XCTAssertEqual(decision.action, .insert)
        XCTAssertGreaterThanOrEqual(decision.contextualFit, 0.72)
    }

    func testDiscoveryCandidateThatBreaksContextIsDeferredForLaterDiscovery() {
        let session = SessionContext(
            startedAt: Date(timeIntervalSince1970: 1),
            mood: SessionMood(valence: 0.85, energy: 0.8, danceability: 0.75, confidence: 1)
        )
        let candidate = TrackCandidate(
            id: "new",
            title: "New Discovery",
            artistName: "New Artist",
            source: .discovery,
            affinity: 0.8,
            freshness: 1,
            explorationValue: 0.9
        )
        let current = AudioFeatures(bpm: 120, energy: 0.8, danceability: 0.75, valence: 0.85)
        let features = AudioFeatures(bpm: 60, energy: 0.1, danceability: 0.1, valence: 0.1)

        let decision = ContextualCandidateEvaluator().evaluate(
            candidate: candidate,
            candidateFeatures: features,
            currentFeatures: current,
            session: session
        )

        XCTAssertEqual(decision.action, .discoverLater)
        XCTAssertLessThan(decision.contextualFit, 0.48)
    }

    func testCandidateAlreadyInQueueIsNeverInsertedAgain() {
        let session = SessionContext(
            startedAt: Date(timeIntervalSince1970: 1),
            queue: [
                SessionTrackSnapshot(
                    trackID: "candidate",
                    title: "Candidate",
                    artistName: "Artist"
                )
            ]
        )
        let candidate = TrackCandidate(
            id: "candidate",
            title: "Candidate",
            artistName: "Artist",
            source: .library,
            affinity: 1
        )

        let decision = ContextualCandidateEvaluator().evaluate(
            candidate: candidate,
            candidateFeatures: nil,
            currentFeatures: nil,
            session: session
        )

        XCTAssertEqual(decision.action, .deferCandidate)
        XCTAssertEqual(decision.contextualFit, 0)
    }

    func testNeutralSignalsProduceStableMidpointDecision() {
        let session = SessionContext(
            startedAt: Date(timeIntervalSince1970: 1),
            mood: SessionMood(valence: 0.5, energy: 0.5, danceability: 0.5, confidence: 1)
        )
        let candidate = TrackCandidate(
            id: "neutral",
            title: "Neutral",
            artistName: "Artist",
            source: .library,
            affinity: 0.5,
            freshness: 0.5
        )

        let decision = ContextualCandidateEvaluator().evaluate(
            candidate: candidate,
            candidateFeatures: nil,
            currentFeatures: nil,
            session: session
        )

        XCTAssertEqual(decision.action, .deferCandidate)
        XCTAssertEqual(decision.contextualFit, 0.5, accuracy: 0.0001)
    }
}
