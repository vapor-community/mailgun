import Vapor
import Foundation

// MARK: - Service

public protocol MailgunProvider {
    func send(_ content: MailgunMessage) throws -> EventLoopFuture<ClientResponse>
    func send(_ content: MailgunTemplateMessage) throws -> EventLoopFuture<ClientResponse>
    func setup(forwarding: MailgunRouteSetup) throws -> EventLoopFuture<ClientResponse>
    func createTemplate(_ template: MailgunTemplate) throws -> EventLoopFuture<ClientResponse>
}

internal protocol _MailgunProvider: MailgunProvider {
    var application: Application { get }
    var storage: MailgunStorage { get }
}

public struct Mailgun: _MailgunProvider {
    let application: Application
    let domain: MailgunDomain
    let storage: MailgunStorage
    
    // MARK: Initialization
    
    public init (_ application: Application, _ domain: MailgunDomain) {
        self.application = application
        self.domain = domain
        self.storage = MailgunStorage(application)
    }
}

// MARK: - Send message

extension Mailgun {
    /// Base API URL based on the current region
    var baseApiUrl: String {
        switch domain.region {
        case .us: return "https://api.mailgun.net/v3"
        case .eu: return "https://api.eu.mailgun.net/v3"
        }
    }
    
    /// Send message
    ///
    /// - Parameters:
    ///   - content: Message
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: MailgunMessage) -> EventLoopFuture<ClientResponse> {
        postRequest(content, endpoint: "messages")
    }

    /// Send message
    ///
    /// - Parameters:
    ///   - content: TemplateMessage
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: MailgunTemplateMessage) -> EventLoopFuture<ClientResponse> {
        postRequest(content, endpoint: "messages")
    }
    
    /// Setup forwarding
    ///
    /// - Parameters:
    ///   - setup: RouteSetup
    ///   - container: Container
    /// - Returns: Future<Response>
    public func setup(forwarding setup: MailgunRouteSetup) -> EventLoopFuture<ClientResponse> {
        postRequest(setup, endpoint: "v3/routes")
    }

    /// Create template
    ///
    /// - Parameters:
    ///   - template: Template
    ///   - container: Container
    /// - Returns: Future<Response>
    public func createTemplate(_ template: MailgunTemplate) -> EventLoopFuture<ClientResponse> {
        postRequest(template, endpoint: "templates")
    }
}

// MARK: - Conversions

extension Array where Element == MailgunMessage.FullEmail {
    var stringArray: [String] {
        map { entry in
            guard let name = entry.name else {
                return entry.email
            }
            return "\"\(name) <\(entry.email)>\""
        }
    }
}
