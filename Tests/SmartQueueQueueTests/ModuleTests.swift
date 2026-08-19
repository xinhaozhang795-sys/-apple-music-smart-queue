import XCTest
@testable import SmartQueueQueue

final class SmartQueueQueueModuleTests: XCTestCase {
    func testModuleBoundaryCompiles() {
        _ = SmartQueueQueueModule.self
    }
}
