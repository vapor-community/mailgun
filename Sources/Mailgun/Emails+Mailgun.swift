import Vapor
import Email
import MailgunKit

extension Application.Emails.Provider {
    public static func mailgun(_ configuration: Mailgun.Configuration) -> Self {
        .init { app in
            app.emails.use {
                LiveMailgunClient(
                    config: configuration,
                    eventLoop: $0.eventLoopGroup.next(),
                    httpClient: $0.http.client.shared,
                    logger: $0.logger
                )
            }
        }
    }
}
