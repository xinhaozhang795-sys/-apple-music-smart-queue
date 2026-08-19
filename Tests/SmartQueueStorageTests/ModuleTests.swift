import XCTest
@testable import SmartQueueStorage

final class SmartQueueStorageModuleTests: XCTestCase {
    func testModuleBoundaryCompiles() {
        _ = SmartQueueStorageModule.self
    }
}
