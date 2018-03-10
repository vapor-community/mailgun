import XCTest

import MailgunTests

var tests = [XCTestCaseEntry]()
tests += MailgunTests.allTests()
XCTMain(tests)