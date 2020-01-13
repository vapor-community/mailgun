import Foundation
import Vapor

public struct MailgunConfiguration {
    /// API key (including "key-" prefix)
    public let apiKey: String
    
    /// Domain
    public let domain: String
    
    /// Region
    public let region: MailgunRegion
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - domain: API domain
    public init(apiKey: String, domain: String, region: MailgunRegion) {
        self.apiKey = apiKey
        self.domain = domain
        self.region = region
    }
    
    var baseApiUrl: String {
        switch region {
        case .us: return "https://api.mailgun.net/v3"
        case .eu: return "https://api.eu.mailgun.net/v3"
        }
    }
    
    /// It will try to initialize configuration with environment variables:
    /// - MG_KEY
    /// - MG_DOMAIN
    /// - MG_REGION
    public static var environment: MailgunConfiguration {
        guard
            let apiKey = Environment.get("MAILGUN_API_KEY"),
            let domain = Environment.get("MAILGUN_DOMAIN"),
            let rawRegion = Environment.get("MAILGUN_REGION")
            else {
            fatalError("Mailgun environmant variables not set")
        }
        guard let region = MailgunRegion(rawValue: rawRegion.lowercased()) else {
            fatalError("Mailgun unable to parse environmant region value")
        }
        return .init(apiKey: apiKey, domain: domain, region: region)
    }
}
