import XCTest
@testable import Mailgun

final class MailgunTests: XCTestCase {
    func testExample() {
        let mailgun = Mailgun(apiKey: "", domain: "")
        
        let content = try req.view().render("Emails/my-email", [
            "name": "Bob"
        ])
        
        let message = Mailgun.Message(
            from: "hello@mail.com",
            to: "recipient@mail.com",
            subject: "Hey There!",
            text: "",
            html: .leaf(content)
        )
        
        let mailgun = try req.make(Mailgun.self)
        return try mailgun.send(message, on: req)
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
