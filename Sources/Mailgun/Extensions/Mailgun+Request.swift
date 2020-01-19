import Vapor

extension Request {
    public var mailgun: MailgunStorage {
        application.mailgun
    }
    
    public func mailgun(_ domain: MailgunDomain? = nil) -> Mailgun {
        application.mailgun(domain)
    }
}
