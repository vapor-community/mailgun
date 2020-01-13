import Vapor
import Foundation


// MARK: - Service

public protocol MailgunProvider {
    var configuration: MailgunConfiguration? { get set }
    func send(_ content: MailgunMessage) throws -> EventLoopFuture<ClientResponse>
    func send(_ content: MailgunTemplateMessage) throws -> EventLoopFuture<ClientResponse>
    func setup(forwarding: MailgunRouteSetup) throws -> EventLoopFuture<ClientResponse>
    func createTemplate(_ template: MailgunTemplate) throws -> EventLoopFuture<ClientResponse>
}

public struct Mailgun: MailgunProvider {
    let application: Application
    
    // MARK: Initialization
    
    public init (_ app: Application) {
        application = app
    }
}

// MARK: - Configuration

extension Mailgun {
    struct ConfigurationKey: StorageKey {
        typealias Value = MailgunConfiguration
    }

    public var configuration: MailgunConfiguration? {
        get {
            application.storage[ConfigurationKey.self]
        }
        nonmutating set {
            application.storage[ConfigurationKey.self] = newValue
        }
    }
}

// MARK: - Send message

extension Mailgun {
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

extension Application {
    public var mailgun: Mailgun { .init(self) }
}

extension Request {
    public var mailgun: Mailgun { .init(application) }
}

// MARK: - Private

fileprivate extension Mailgun {
    func encode(apiKey: String) throws -> String {
        guard let apiKeyData = "api:\(apiKey)".data(using: .utf8) else {
            throw MailgunError.encodingProblem
        }
        let authKey = apiKeyData.base64EncodedData()
        guard let authKeyEncoded = String.init(data: authKey, encoding: .utf8) else {
            throw MailgunError.encodingProblem
        }
        return authKeyEncoded
    }

    private func postRequest<Message: Content>(_ content: Message, endpoint: String) -> EventLoopFuture<ClientResponse> {
        guard let configuration = self.configuration else {
            fatalError("Mailgun not configured. Use app.mailgun.configuration = ...")
        }
        
        return application.eventLoopGroup.future().flatMapThrowing { _ -> HTTPHeaders in
            let authKeyEncoded = try self.encode(apiKey: configuration.apiKey)
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Basic \(authKeyEncoded)")
            return headers
        }.flatMap { headers in
            let mailgunURI = URI(string: "\(configuration.baseApiUrl)/\(configuration.domain)/\(endpoint)")
            return self.application.client.post(mailgunURI, headers: headers) { req in
                try req.content.encode(content)
            }.flatMapThrowing {
                try self.process($0)
            }
        }
    }
    
    private func process(_ response: ClientResponse) throws -> ClientResponse {
        switch true {
        case response.status == .ok:
            return response
        case response.status == .unauthorized:
            throw MailgunError.authenticationFailed
        default:
            if let body = response.body, let err = try? JSONDecoder().decode(MailgunErrorResponse.self, from: body) {
                if err.message.hasPrefix("template") {
                    throw MailgunError.unableToCreateTemplate(err)
                } else {
                    throw MailgunError.unableToSendEmail(err)
                }
            }
            throw MailgunError.unknownError(response)
        }
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
