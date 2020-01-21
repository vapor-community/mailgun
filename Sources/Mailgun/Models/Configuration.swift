import Foundation
import Vapor

public struct MailgunConfiguration {
    /// API key (including "key-" prefix)
    public let apiKey: String
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - domain: API domain
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// It will try to initialize configuration with environment variables:
    /// - MAILGUN_API_KEY
    public static var environment: MailgunConfiguration {
        guard let apiKey = Environment.get("MAILGUN_API_KEY") else {
            fatalError("Mailgun environmant variables not set")
        }
        return .init(apiKey: apiKey)
    }
}
