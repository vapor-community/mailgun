import Vapor
import Foundation

// MARK: - Service
public protocol MailgunProvider {
    var eventLoop: EventLoop { get set }
    
    func send(_ content: MailgunMessage) -> EventLoopFuture<HTTPClient.Response>
    func send(_ content: MailgunTemplateMessage) -> EventLoopFuture<HTTPClient.Response>
    func setup(forwarding: MailgunRouteSetup) -> EventLoopFuture<HTTPClient.Response>
    func createTemplate(_ template: MailgunTemplate) -> EventLoopFuture<HTTPClient.Response>
}

extension MailgunProvider {
    public func hopped(to eventLoop: EventLoop) -> MailgunProvider {
        var copy = self
        copy.eventLoop = eventLoop
        return copy
    }
}

public struct MailgunClient: MailgunProvider {
    public var eventLoop: EventLoop
    let config: MailgunConfiguration
    let client: HTTPClient
    let domain: MailgunDomain
    
    // MARK: Initialization
    public init(
        config: MailgunConfiguration,
        eventLoop: EventLoop,
        client: HTTPClient,
        domain: MailgunDomain
    ) {
        self.config = config
        self.eventLoop = eventLoop
        self.client = client
        self.domain = domain
    }
}

// MARK: - Send message

extension MailgunClient {
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
    public func send(_ content: MailgunMessage) -> EventLoopFuture<HTTPClient.Response> {
        postRequest(content, endpoint: "messages")
    }

    /// Send message
    ///
    /// - Parameters:
    ///   - content: TemplateMessage
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: MailgunTemplateMessage) -> EventLoopFuture<HTTPClient.Response> {
        postRequest(content, endpoint: "messages")
    }
    
    /// Setup forwarding
    ///
    /// - Parameters:
    ///   - setup: RouteSetup
    ///   - container: Container
    /// - Returns: Future<Response>
    public func setup(forwarding setup: MailgunRouteSetup) -> EventLoopFuture<HTTPClient.Response> {
        postRequest(setup, endpoint: "v3/routes")
    }

    /// Create template
    ///
    /// - Parameters:
    ///   - template: Template
    ///   - container: Container
    /// - Returns: Future<Response>
    public func createTemplate(_ template: MailgunTemplate) -> EventLoopFuture<HTTPClient.Response> {
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
