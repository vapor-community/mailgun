import Vapor

extension Request {
    /// Mailgun with default domain.
    /// Default domain should be configured in advance through `app.mailgun.defaultDomain`
    public func mailgun() -> MailgunProvider {
        application.mailgun().delegating(to: self.eventLoop)
    }
    
    /// Mailgun with selected domain.
    public func mailgun(_ domain: MailgunDomain) -> MailgunProvider {
        application.mailgun(domain).delegating(to: self.eventLoop)
    }
}
