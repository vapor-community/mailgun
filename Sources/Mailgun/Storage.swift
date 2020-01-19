import Vapor

public struct MailgunStorage {
    let application: Application
    
    init (_ application: Application) {
        self.application = application
    }
    
    struct ConfigurationKey: StorageKey {
        typealias Value = MailgunConfiguration
    }

    /// Global Mailgun configuration for all the domains
    public var configuration: MailgunConfiguration? {
        get {
            application.storage[ConfigurationKey.self]
        }
        nonmutating set {
            application.storage[ConfigurationKey.self] = newValue
        }
    }
    
    struct DefaultDomainKey: StorageKey {
        typealias Value = MailgunDomain
    }

    /// Default mailgun domain which will be used when you call `app.mailgun.`
    public var defaultDomain: MailgunDomain? {
        get {
            application.storage[DefaultDomainKey.self]
        }
        nonmutating set {
            application.storage[DefaultDomainKey.self] = newValue
        }
    }
}
