import XCTest
@testable import SmartQueueCore

final class AdaptiveTasteLearnerTests: XCTestCase {
    func testPositiveFeedbackMovesTasteTowardObservedFeatures() {
        let learner = AdaptiveTasteLearner(learningRate: 0.5)
        let profile = TasteProfile()
        let features = AudioFeatures(energy: 1, danceability: 1, valence: 1)
        let event = ListeningEvent(trackID: "song", outcome: .completed)

        let updated = learner.update(profile: profile, event: event, features: features)

        XCTAssertGreaterThan(updated.preferredEnergy, profile.preferredEnergy)
        XCTAssertGreaterThan(updated.preferredDanceability, profile.preferredDanceability)
        XCTAssertGreaterThan(updated.preferredValence, profile.preferredValence)
    }

    func testStrongNegativeFeedbackMovesTasteAwayFromObservedFeatures() {
        let learner = AdaptiveTasteLearner(learningRate: 0.5)
        let profile = TasteProfile()
        let features = AudioFeatures(energy: 1, danceability: 1, valence: 1)
        let event = ListeningEvent(trackID: "song", progress: 0.05, outcome: .skipped)

        let updated = learner.update(profile: profile, event: event, features: features)

        XCTAssertLessThan(updated.preferredEnergy, profile.preferredEnergy)
        XCTAssertLessThan(updated.preferredDanceability, profile.preferredDanceability)
        XCTAssertLessThan(updated.preferredValence, profile.preferredValence)
    }

    func testNeutralFeedbackDoesNotChangeTaste() {
        let learner = AdaptiveTasteLearner(learningRate: 0.5)
        let profile = TasteProfile()
        let features = AudioFeatures(energy: 1, danceability: 0, valence: 1)
        let event = ListeningEvent(trackID: "song", outcome: .started)

        XCTAssertEqual(learner.update(profile: profile, event: event, features: features), profile)
    }
}
