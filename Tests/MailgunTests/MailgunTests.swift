import Configuration
import Mailgun
import Testing
import VaporTesting

@Suite("Mailgun Tests")
struct MailgunTests {
    private func configure(_ app: Application) async throws {
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
            try await JSONProvider(filePath: "testing.config.json")
        ])
        app.mailgun.configuration = try .init(config: config)
        #expect(app.mailgun.configuration?.apiKey == "test-api-key")
    }

    let message = MailgunMessage(
        from: "postmaster@example.com",
        to: "example@gmail.com",
        subject: "Newsletter",
        text: "This is a newsletter",
        html: "<h1>This is a newsletter</h1>"
    )

    @Test("Access client from Application", arguments: [nil, MailgunDomain("mg.myapp2.com", .eu)])
    func application(domain: MailgunDomain?) async throws {
        try await withApp(configure: configure) { app in
            await #expect(throws: MailgunError.authenticationFailed) {
                try await app.mailgun.client(domain).send(message)
            }
        }
    }

    @Test("Access client from Request", arguments: [nil, MailgunDomain("mg.myapp2.com", .eu)])
    func request(domain: MailgunDomain?) async throws {
        try await withApp(configure: configure) { app in
            app.get("test") { req async throws -> Response in
                await #expect(throws: MailgunError.authenticationFailed) {
                    try await req.mailgunClient(domain).send(message)
                }
                return Response(status: .ok)
            }

            try await app.test(.GET, "test")
        }
    }
}
