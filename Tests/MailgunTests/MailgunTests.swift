import XCTest
import XCTVapor
import Email
@testable import Mailgun

final class MailgunTests: XCTestCase {
    func test_sendEmail() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        let domain = Mailgun.Domain("", .us)
        let config = Mailgun.Configuration(apiKey: "", defaultDomain: domain)
        app.emails.use(.mailgun(config))
        
        // Multiple attachments will result in a warning.
        let message = EmailMessage.init(
            from: "test@test.com",
            to: "mads@test.com",
            subject: "test email",
            content: .html("<h1>Hey mads!</h2>"),
            attachments: [
                .attachment(File.init(data: "this is a text file", filename: "test.txt")),
                .attachment(File.init(data: "this is a text file", filename: "test.txt"))
            ]
        )
        try app.email.send(message).wait()
    }
}
