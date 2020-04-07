import Vapor

extension Request {
    /// Mailgun with default domain.
    /// Default domain should be configured in advance through `app.mailgun.defaultDomain`
    public func mailgun() -> MailgunProvider {
        application.mailgun().for(self)
    }
    
    /// Mailgun with selected domain.
    public func mailgun(_ domain: MailgunDomain) -> MailgunProvider {
        application.mailgun(domain).for(self)
    }
}

extension MailgunProvider {
    func `for`(_ req: Request) -> MailgunProvider {
        self.hopped(to: req.eventLoop)
    }
}
