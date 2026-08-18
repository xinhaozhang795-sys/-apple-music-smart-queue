import XCTest
@testable import SmartQueueCore

final class AudioFeaturesProviderTests: XCTestCase {
    func testNullProviderReturnsNoFeatures() async throws {
        let provider = NullAudioFeaturesProvider()
        let result = try await provider.features(for: "song-1")
        XCTAssertNil(result)
    }
}
