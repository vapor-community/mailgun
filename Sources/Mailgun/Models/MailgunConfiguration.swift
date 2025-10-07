import Configuration
import Vapor

public struct MailgunConfiguration: Sendable {
    /// API key (including "key-" prefix)
    public let apiKey: String

    /// Default domain
    public let defaultDomain: MailgunDomain

    /// Create a configuration with explicit values.
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - defaultDomain: Default API domain to use
    public init(apiKey: String, defaultDomain: MailgunDomain) {
        self.apiKey = apiKey
        self.defaultDomain = defaultDomain
    }

    /// Creates a new Mailgun client configuration using values from the provided reader.
    ///
    /// ## Configuration keys
    /// - `apiKey` (string, required): The API key for authenticating requests.
    /// - `defaultDomain.domain` (string, required): The default domain to use for sending emails.
    /// - `defaultDomain.region` (string, required): The region for the default domain, either "us" or "eu".
    ///
    /// - Parameter config: The config reader to read configuration values from.
    public init(config: ConfigReader) throws {
        self.apiKey = try config.requiredString(forKey: "apiKey", isSecret: true)
        self.defaultDomain = .init(
            try config.requiredString(forKey: "defaultDomain.domain"),
            try config.requiredString(forKey: "defaultDomain.region", as: MailgunRegion.self)
        )
    }
}
