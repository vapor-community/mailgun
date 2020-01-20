import Vapor

extension Request {
    /// Mailgun with default domain.
    /// Default domain should be configured in advance through `app.mailgun.defaultDomain`
    public func mailgun() -> Mailgun {
        application.mailgun()
    }
    
    /// Mailgun with selected domain.
    public func mailgun(_ domain: MailgunDomain) -> Mailgun {
        application.mailgun(domain)
    }
}
