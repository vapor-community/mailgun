import Foundation
import Vapor

public struct MailgunConfiguration {
    /// API key (including "key-" prefix)
    public let apiKey: String
    
    /// API base URL to send requests to, e.g. an internal egress proxy or a
    /// local stub. `nil` uses the URL belonging to the domain's region.
    public let baseApiUrl: String?

    /// Initializer
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - baseApiUrl: API base URL, or `nil` to derive it from the domain's region
    public init(apiKey: String, baseApiUrl: String? = nil) {
        self.apiKey = apiKey
        self.baseApiUrl = baseApiUrl
    }
    
    /// It will try to initialize configuration with environment variables:
    /// - MAILGUN_API_KEY
    /// - MAILGUN_API_BASE_URL (optional)
    public static var environment: MailgunConfiguration {
        guard let apiKey = Environment.get("MAILGUN_API_KEY") else {
            fatalError("Mailgun environment variables not set")
        }
        return .init(apiKey: apiKey, baseApiUrl: Environment.get("MAILGUN_API_BASE_URL"))
    }
}
