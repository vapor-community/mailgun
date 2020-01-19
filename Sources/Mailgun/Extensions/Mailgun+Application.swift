import Vapor

extension Application {
    public var mailgun: MailgunStorage {
        .init(self)
    }
    
    /// Mailgun with selected or default domain.
    /// Default domain should be configured in advance through `app.mailgun.defaultDomain`
    public func mailgun(_ domain: MailgunDomain? = nil) -> Mailgun {
        if let domain = domain {
            return .init(self, domain)
        }
        let storage = MailgunStorage(self)
        guard let defaultDomain = storage.defaultDomain else {
            fatalError("Mailgun default domain not configured. Use app.mailgun.defaultDomain = ...")
        }
        return .init(self, defaultDomain)
    }
}
