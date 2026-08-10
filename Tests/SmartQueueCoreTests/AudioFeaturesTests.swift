import XCTest
@testable import SmartQueueCore

final class AudioFeaturesTests: XCTestCase {
    func testSimilarFeaturesScoreHigher() {
        let scorer = ContinuityScorer()
        let current = AudioFeatures(bpm: 120, energy: 0.8, danceability: 0.8, valence: 0.7)
        let similar = AudioFeatures(bpm: 124, energy: 0.78, danceability: 0.82, valence: 0.72)
        let distant = AudioFeatures(bpm: 70, energy: 0.2, danceability: 0.2, valence: 0.1)

        XCTAssertGreaterThan(
            scorer.score(from: current, to: similar),
            scorer.score(from: current, to: distant)
        )
    }

    func testMissingFeaturesReturnNeutralScore() {
        let scorer = ContinuityScorer()
        XCTAssertEqual(
            scorer.score(from: AudioFeatures(), to: AudioFeatures()),
            0.5
        )
    }
}
