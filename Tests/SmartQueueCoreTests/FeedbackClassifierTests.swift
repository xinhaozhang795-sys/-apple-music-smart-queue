import XCTest
@testable import SmartQueueCore

final class FeedbackClassifierTests: XCTestCase {
    private let classifier = FeedbackClassifier()

    func testCompletedIsPositive() {
        let event = ListeningEvent(trackID: "a", progress: 1, outcome: .completed)
        XCTAssertEqual(classifier.classify(event), .positive)
        XCTAssertEqual(classifier.learningSignal(for: event), 0.75)
    }

    func testFavoriteAndReplayAreStrongPositive() {
        XCTAssertEqual(
            classifier.classify(ListeningEvent(trackID: "a", outcome: .favorited)),
            .strongPositive
        )
        XCTAssertEqual(
            classifier.classify(ListeningEvent(trackID: "a", outcome: .replayed)),
            .strongPositive
        )
    }

    func testEarlySkipIsStrongNegative() {
        let event = ListeningEvent(trackID: "a", progress: 0.1, outcome: .skipped)
        XCTAssertEqual(classifier.classify(event), .strongNegative)
        XCTAssertEqual(classifier.learningSignal(for: event), -1)
    }

    func testMidSkipIsNegativeAndLateSkipIsNeutral() {
        let mid = ListeningEvent(trackID: "a", progress: 0.35, outcome: .skipped)
        let late = ListeningEvent(trackID: "a", progress: 0.75, outcome: .skipped)

        XCTAssertEqual(classifier.classify(mid), .negative)
        XCTAssertEqual(classifier.classify(late), .neutral)
    }

    func testStartedIsNeutral() {
        let event = ListeningEvent(trackID: "a", outcome: .started)
        XCTAssertEqual(classifier.classify(event), .neutral)
        XCTAssertEqual(classifier.learningSignal(for: event), 0)
    }
}
