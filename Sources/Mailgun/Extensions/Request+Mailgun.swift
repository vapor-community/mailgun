import Vapor

extension Request {
    /// Create a Mailgun client
    ///
    /// - Parameter domain: Domain to use, if `nil` it will use the default domain configured in `app.mailgun.defaultDomain`
    /// - Returns: Mailgun client
    public func mailgunClient(_ domain: MailgunDomain? = nil) -> MailgunProvider {
        self.application.mailgun.client(domain)
    }
}
