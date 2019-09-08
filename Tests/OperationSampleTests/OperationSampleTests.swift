import XCTest
@testable import OperationSample

final class OperationSampleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OperationSample().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
