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

    func testQueuePolicySanitizesInvalidSizesAndWeights() {
        let policy = QueuePolicy(
            targetSize: -1,
            refillThreshold: -2,
            refillBatchSize: -3,
            personalPreferenceWeight: .infinity,
            transitionWeight: -.infinity,
            duplicatePenalty: .nan
        )

        XCTAssertEqual(policy.targetSize, 0)
        XCTAssertEqual(policy.refillThreshold, 0)
        XCTAssertEqual(policy.refillBatchSize, 0)
        XCTAssertEqual(policy.personalPreferenceWeight, 0)
        XCTAssertEqual(policy.transitionWeight, 0)
        XCTAssertEqual(policy.duplicatePenalty, 0)
    }

    func testSmartFlowPlannerCarriesAudioFeaturesBetweenSelections() {
        let firstFeatures = AudioFeatures(bpm: 100, energy: 0.8, danceability: 0.8, valence: 0.8)
        let secondFeatures = AudioFeatures(bpm: 100, energy: 0.8, danceability: 0.8, valence: 0.8)
        let contrastingFeatures = AudioFeatures(bpm: 200, energy: 0.1, danceability: 0.1, valence: 0.1)

        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Artist",
            audioFeatures: firstFeatures
        )
        let candidates = [
            TrackCandidate(id: "second", title: "Second", artistName: "A", source: .discovery, audioFeatures: secondFeatures),
            TrackCandidate(id: "contrast", title: "Contrast", artistName: "B", source: .discovery, audioFeatures: contrastingFeatures),
            TrackCandidate(id: "third", title: "Third", artistName: "C", source: .discovery, audioFeatures: secondFeatures)
        ]

        let planned = SmartFlowPlanner(mode: .smooth).plan(
            candidates: candidates,
            current: current,
            count: 3
        )

        XCTAssertEqual(planned.count, 3)
        XCTAssertEqual(planned[0].candidate.id, "second")
        XCTAssertEqual(planned[1].candidate.audioFeatures, secondFeatures)
    }
}
