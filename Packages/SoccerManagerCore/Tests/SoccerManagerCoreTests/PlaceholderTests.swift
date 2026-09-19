import XCTest
@testable import SoccerManagerCore

final class PlaceholderTests: XCTestCase {
    func testCoreVersion() {
        XCTAssertEqual(coreVersion(), "0.1.0")
    }
}
