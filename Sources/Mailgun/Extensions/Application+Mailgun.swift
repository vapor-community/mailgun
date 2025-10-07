import Synchronization
public import Vapor

extension Application {
    public struct Mailgun {
        public typealias MailgunFactory = @Sendable (Application, MailgunDomain?) -> any MailgunProvider

        public struct Provider {
            public static var live: Self {
                .init {
                    $0.mailgun.use { app, domain in
                        guard let config = app.mailgun.configuration else {
                            fatalError("Mailgun not configured, use: app.mailgun.configuration = .init()")
                        }

                        let useDomain: MailgunDomain
                        if let domain {
                            useDomain = domain
                        } else {
                            useDomain = config.defaultDomain
                        }

                        return MailgunClient(
                            apiKey: config.apiKey,
                            domain: useDomain,
                            client: app.client
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

        private final class Storage: Sendable {
            private struct SendableBox: Sendable {
                var configuration: MailgunConfiguration?
                var makeClient: MailgunFactory?
            }

            private let sendableBox: Mutex<SendableBox>

            var configuration: MailgunConfiguration? {
                get { sendableBox.withLock { $0.configuration } }
                set { sendableBox.withLock { $0.configuration = newValue } }
            }

            var makeClient: MailgunFactory? {
                get { sendableBox.withLock { $0.makeClient } }
                set { sendableBox.withLock { $0.makeClient = newValue } }
            }

            init() {
                self.sendableBox = .init(SendableBox())
            }
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

        public func client(_ domain: MailgunDomain? = nil) -> any MailgunProvider {
            guard let makeClient = storage.makeClient else {
                fatalError("Mailgun not configured, use: app.mailgun.use(.real)")
            }

            return makeClient(app, domain)
        }
    }

    public var mailgun: Mailgun {
        .init(app: self)
    }
}
