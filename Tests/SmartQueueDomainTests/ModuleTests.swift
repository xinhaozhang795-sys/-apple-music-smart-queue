import XCTest
@testable import SmartQueueDomain

final class SmartQueueDomainModuleTests: XCTestCase {
    func testModuleBoundaryCompiles() {
        _ = SmartQueueDomainModule.self
    }
}
