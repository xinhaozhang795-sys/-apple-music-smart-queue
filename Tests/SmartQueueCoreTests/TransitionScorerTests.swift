import XCTest
@testable import SmartQueueCore

final class TransitionScorerTests: XCTestCase {
    private let scorer = TransitionScorer()

    func testMissingFeaturesUseNeutralScore() {
        let score = scorer.score(TransitionContext())

        XCTAssertEqual(score.overall, 0.5, accuracy: 0.0001)
        XCTAssertEqual(score.bpm, 0.5, accuracy: 0.0001)
    }

    func testMatchingFeaturesProduceHighTransitionScore() {
        let features = AudioFeatures(
            bpm: 120,
            energy: 0.8,
            danceability: 0.7,
            valence: 0.6
        )
        let score = scorer.score(TransitionContext(current: features, candidate: features))

        XCTAssertEqual(score.overall, 1.0, accuracy: 0.0001)
    }

    func testHalfTimeBPMRelationshipIsRecognized() {
        let current = AudioFeatures(bpm: 80, energy: 0.8, danceability: 0.7, valence: 0.6)
        let candidate = AudioFeatures(bpm: 160, energy: 0.8, danceability: 0.7, valence: 0.6)
        let score = scorer.score(TransitionContext(current: current, candidate: candidate))

        XCTAssertEqual(score.bpm, 1.0, accuracy: 0.0001)
    }

    func testLargeFeatureDifferenceLowersScore() {
        let current = AudioFeatures(bpm: 80, energy: 0.1, danceability: 0.1, valence: 0.1)
        let candidate = AudioFeatures(bpm: 160, energy: 0.9, danceability: 0.9, valence: 0.9)
        let score = scorer.score(TransitionContext(current: current, candidate: candidate))

        XCTAssertLessThan(score.overall, 0.5)
    }
}
