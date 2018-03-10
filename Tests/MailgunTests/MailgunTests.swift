import XCTest
@testable import Mailgun

final class MailgunTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Mailgun().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
