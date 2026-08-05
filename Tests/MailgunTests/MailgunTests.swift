import Vapor
import XCTest
@testable import Mailgun

final class MailgunTests: XCTestCase {
    private var app: Application!

    override func setUp() {
        super.setUp()
        app = Application(.testing)
    }

    override func tearDown() {
        app.shutdown()
        app = nil
        super.tearDown()
    }

    private func client(_ config: MailgunConfiguration, region: MailgunRegion) -> MailgunClient {
        MailgunClient(
            config: config,
            eventLoop: app.eventLoopGroup.next(),
            client: app.client,
            domain: .init("example.com", region)
        )
    }

    func testBaseApiUrlFallsBackToTheRegion() {
        let config = MailgunConfiguration(apiKey: "key-test")

        XCTAssertEqual(client(config, region: .us).baseApiUrl, "https://api.mailgun.net/v3")
        XCTAssertEqual(client(config, region: .eu).baseApiUrl, "https://api.eu.mailgun.net/v3")
    }

    func testConfiguredBaseApiUrlTakesPrecedenceOverTheRegion() {
        let config = MailgunConfiguration(apiKey: "key-test", baseApiUrl: "https://mailgun.proxy.internal/v3")

        XCTAssertEqual(client(config, region: .us).baseApiUrl, "https://mailgun.proxy.internal/v3")
        XCTAssertEqual(client(config, region: .eu).baseApiUrl, "https://mailgun.proxy.internal/v3")
    }

    func testEnvironmentConfigurationReadsTheBaseApiUrl() {
        setenv("MAILGUN_API_KEY", "key-test", 1)
        setenv("MAILGUN_API_BASE_URL", "https://mailgun.proxy.internal/v3", 1)
        defer {
            unsetenv("MAILGUN_API_KEY")
            unsetenv("MAILGUN_API_BASE_URL")
        }

        XCTAssertEqual(MailgunConfiguration.environment.baseApiUrl, "https://mailgun.proxy.internal/v3")
    }

    func testEnvironmentConfigurationLeavesTheBaseApiUrlUnsetWhenAbsent() {
        setenv("MAILGUN_API_KEY", "key-test", 1)
        unsetenv("MAILGUN_API_BASE_URL")
        defer { unsetenv("MAILGUN_API_KEY") }

        XCTAssertNil(MailgunConfiguration.environment.baseApiUrl)
    }

    static var allTests = [
        ("testBaseApiUrlFallsBackToTheRegion", testBaseApiUrlFallsBackToTheRegion),
        ("testConfiguredBaseApiUrlTakesPrecedenceOverTheRegion", testConfiguredBaseApiUrlTakesPrecedenceOverTheRegion),
        ("testEnvironmentConfigurationReadsTheBaseApiUrl", testEnvironmentConfigurationReadsTheBaseApiUrl),
        ("testEnvironmentConfigurationLeavesTheBaseApiUrlUnsetWhenAbsent", testEnvironmentConfigurationLeavesTheBaseApiUrlUnsetWhenAbsent),
    ]
}
