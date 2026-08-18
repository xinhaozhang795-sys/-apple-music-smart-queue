import XCTest
@testable import SmartQueueCore

final class TransitionPlanTests: XCTestCase {
    func testPlanChainsCurrentAndCandidateFeatures() {
        let currentFeatures = AudioFeatures(bpm: 100, energy: 0.8, danceability: 0.8, valence: 0.8)
        let nextFeatures = AudioFeatures(bpm: 100, energy: 0.8, danceability: 0.8, valence: 0.8)
        let finalFeatures = AudioFeatures(bpm: 180, energy: 0.2, danceability: 0.2, valence: 0.2)

        let current = CurrentTrackContext(
            trackID: "current",
            title: "Current",
            artistName: "Current Artist",
            audioFeatures: currentFeatures
        )
        let candidates = [
            ScoredCandidate(
                candidate: TrackCandidate(id: "next", title: "Next", artistName: "A", source: .discovery, audioFeatures: nextFeatures),
                score: 1
            ),
            ScoredCandidate(
                candidate: TrackCandidate(id: "final", title: "Final", artistName: "B", source: .discovery, audioFeatures: finalFeatures),
                score: 1
            )
        ]

        let plan = TransitionPlan.make(current: current, candidates: candidates)

        XCTAssertEqual(plan.steps.map(\.fromTrackID), ["current", "next"])
        XCTAssertEqual(plan.steps.map(\.toTrackID), ["next", "final"])
        XCTAssertEqual(plan.steps.count, 2)
        XCTAssertEqual(plan.firstDecision?.strategy, .crossfade)
        XCTAssertEqual(plan.steps[1].decision.strategy, .naturalCut)
    }
}
