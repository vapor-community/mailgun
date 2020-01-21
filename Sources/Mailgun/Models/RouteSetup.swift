import Vapor
import Foundation

public struct MailgunRouteSetup: Content {
    public static var defaultContentType: HTTPMediaType = .urlEncodedForm
    
    public let priority: Int
    public let description: String
    public let filter: String
    public let action: [String]
    
    public init(forwardURL: String, description: String) {
        self.priority = 0
        self.description = description
        self.filter = "catch_all()"
        self.action = ["forward('\(forwardURL)')", "stop()"]
    }
    
    enum CodingKeys: String, CodingKey {
        case priority
        case description
        case filter = "expression"
        case action
    }
}
