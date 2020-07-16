import Vapor

extension Application {
    public struct Mailgun {
        public typealias MailgunFactory = (Application, MailgunDomain?) -> MailgunProvider
        
        public struct Provider {
            public static var live: Self {
                .init {
                    $0.mailgun.use { app, domain in
                        guard let config = app.mailgun.configuration else {
                            fatalError("Mailgun not configured, use: app.mailgun.configuration = .init()")
                        }
                        
                        let useDomain: MailgunDomain
                        
                        if let domain = domain {
                            useDomain = domain
                        } else {
                            guard let defaultDomain = app.mailgun.defaultDomain else {
                                fatalError("Mailgun default domain not configured, use: app.mailgun.defaultDomain = .init()")
                            }
                            
                            useDomain = defaultDomain
                        }
                        
                        return MailgunClient(
                            config: config,
                            eventLoop: app.eventLoopGroup.next(),
                            client: app.client,
                            domain: useDomain
                        )
                    }
                }
            }
            
            public let run: ((Application) -> Void)
            
            public init(_ run: @escaping ((Application) -> Void)) {
                self.run = run
            }
        }
        
        let app: Application
        
        private final class Storage {
            var defaultDomain: MailgunDomain?
            var configuration: MailgunConfiguration?
            var makeClient: MailgunFactory?
            
            init() {}
        }
        
        private struct Key: StorageKey {
            typealias Value = Storage
        }
        
        private var storage: Storage {
            if app.storage[Key.self] == nil {
                self.initialize()
            }
            
            return app.storage[Key.self]!
        }
        
        public func use(_ make: @escaping MailgunFactory) {
            storage.makeClient = make
        }
        
        public func use(_ provider: Application.Mailgun.Provider) {
            provider.run(app)
        }
        
        private func initialize() {
            app.storage[Key.self] = .init()
            app.mailgun.use(.live)
        }
        
        public var configuration: MailgunConfiguration? {
            get { storage.configuration }
            nonmutating set { storage.configuration = newValue }
        }
        
        public var defaultDomain: MailgunDomain? {
            get { storage.defaultDomain }
            nonmutating set { storage.defaultDomain = newValue }
        }
        
        public func client(_ domain: MailgunDomain? = nil) -> MailgunProvider {
            guard let makeClient = storage.makeClient else {
                fatalError("Mailgun not configured, use: app.mailgun.use(.real)")
            }
            
            return makeClient(app, domain)
        }
    }
    
    public var mailgun: Mailgun {
        .init(app: self)
    }
    
    public func mailgun(_ domain: MailgunDomain? = nil) -> MailgunProvider {
        self.mailgun.client(domain)
    }
}
