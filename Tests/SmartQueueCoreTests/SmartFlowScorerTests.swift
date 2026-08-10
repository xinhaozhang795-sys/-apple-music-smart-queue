import XCTest
@testable import SmartQueueCore

final class SmartFlowScorerTests: XCTestCase {
    func testFlowScoreRewardsContinuityAndAffinity() {
        let scorer = SmartFlowScorer()
        let candidate = TrackCandidate(
            id: "track-2",
            title: "Next",
            artistName: "Artist",
            source: .personalRecommendation,
            affinity: 0.9,
            continuity: 0.0,
            freshness: 0.8
        )
        let features = AudioFeatures(bpm: 120, energy: 0.8, danceability: 0.8, valence: 0.7)

        let score = scorer.score(
            candidate: candidate,
            currentFeatures: features,
            candidateFeatures: AudioFeatures(bpm: 122, energy: 0.78, danceability: 0.82, valence: 0.72),
            recommendationStrength: 1.0,
            discoveryValue: 0.5,
            diversityValue: 0.8
        )

        XCTAssertGreaterThan(score, 0.6)
    }
}
