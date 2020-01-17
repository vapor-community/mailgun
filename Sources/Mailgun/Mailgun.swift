import Vapor
import Foundation


// MARK: - Service

public protocol MailgunProvider: Service {
    var apiKey: String { get }
    func send(_ content: Mailgun.Message, domain: Mailgun.DomainConfig, on container: Container) throws -> Future<Response>
    func send(_ content: Mailgun.TemplateMessage, domain: Mailgun.DomainConfig, on container: Container) throws -> Future<Response>
    func setup(forwarding: RouteSetup, domain: Mailgun.DomainConfig, with container: Container) throws -> Future<Response>
    func createTemplate(_ template: Mailgun.Template, domain: Mailgun.DomainConfig, on container: Container) throws -> Future<Response>
}

// MARK: - Engine

public struct Mailgun: MailgunProvider {
    
    /// Describes a region: US or EU
    public enum Region {
        case us
        case eu
    }
    
    public enum Error: Debuggable {
        
        /// Encoding problem
        case encodingProblem
        
        /// Failed authentication
        case authenticationFailed
        
        /// Failed to send email (with error message)
        case unableToSendEmail(ErrorResponse)

        /// Failed to create template (with error message)
        case unableToCreateTemplate(ErrorResponse)

        /// Generic error
        case unknownError(Response)
        
        /// Identifier
        public var identifier: String {
            switch self {
            case .encodingProblem:
                return "mailgun.encoding_error"
            case .authenticationFailed:
                return "mailgun.auth_failed"
            case .unableToSendEmail:
                return "mailgun.send_email_failed"
            case .unableToCreateTemplate:
                return "mailgun.create_template_failed"
            case .unknownError:
                return "mailgun.unknown_error"
            }
        }
        
        /// Reason
        public var reason: String {
            switch self {
            case .encodingProblem:
                return "Encoding problem"
            case .authenticationFailed:
                return "Failed authentication"
            case .unableToSendEmail(let err):
                return "Failed to send email (\(err.message))"
            case .unableToCreateTemplate(let err):
                return "Failed to create template (\(err.message))"
            case .unknownError:
                return "Generic error"
            }
        } 
    }
    
    /// Error response object
    public struct ErrorResponse: Decodable {
        
        /// Error messsage
        public let message: String
        
    }
    
    /// API key (including "key-" prefix)
    public let apiKey: String

    // MARK: Initialization

    /// Initializer
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - domains: DomainConfigs - Mailgun.DomainConfig("example.com", region: .us)
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: Send message
    
    /// Send message
    ///
    /// - Parameters:
    ///   - content: Message
    ///   - domain: String? 
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: Message, domain: DomainConfig, on container: Container) throws -> Future<Response> {
        return try postRequest(content, endpoint: "messages", domain: domain, on: container)
    }

    // MARK: Send message
    
    /// Send message
    ///
    /// - Parameters:
    ///   - content: TemplateMessage
    ///   - domain: String? 
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: TemplateMessage, domain: DomainConfig, on container: Container) throws -> Future<Response> {
        return try postRequest(content, endpoint: "messages", domain: domain, on: container)
    }
    
    /// Setup forwarding
    ///
    /// - Parameters:
    ///   - setup: RouteSetup
    ///   - domain: String? 
    ///   - container: Container
    /// - Returns: Future<Response>
    public func setup(forwarding setup: RouteSetup, domain: DomainConfig, with container: Container) throws -> Future<Response> {
        return try postRequest(setup, endpoint: "v3/routes", domain: domain, on: container)
    }

    /// Create template
    ///
    /// - Parameters:
    ///   - template: Template
    ///   - domain: String? 
    ///   - container: Container
    /// - Returns: Future<Response>
    public func createTemplate(_ template: Template, domain: DomainConfig, on container: Container) throws -> Future<Response> {
        return try postRequest(template, endpoint: "templates", domain: domain, on: container)
    }
}

// MARK: Private

fileprivate extension Mailgun {
    private func baseApiUrl(for domainConfig: DomainConfig) -> String {
        return domainConfig.region == .eu ? "https://api.eu.mailgun.net/v3" : "https://api.mailgun.net/v3"
    }
    
    func encode(apiKey: String) throws -> String {
        guard let apiKeyData = "api:\(apiKey)".data(using: .utf8) else {
            throw Error.encodingProblem
        }
        let authKey = apiKeyData.base64EncodedData()
        guard let authKeyEncoded = String.init(data: authKey, encoding: .utf8) else {
            throw Error.encodingProblem
        }
        
        return authKeyEncoded
    }
    
    private func process(_ response: Response) throws -> Response {
        switch true {
        case response.http.status.code == HTTPStatus.ok.code:
            return response
        case response.http.status.code == HTTPStatus.unauthorized.code:
            throw Error.authenticationFailed
        default:
            if let data = response.http.body.data, let err = (try? JSONDecoder().decode(ErrorResponse.self, from: data)) {
                if (err.message.hasPrefix("template")) {
                    throw Error.unableToCreateTemplate(err)
                } else {
                    throw Error.unableToSendEmail(err)
                }
            }
            throw Error.unknownError(response)
        }
    }

    private func postRequest<Message: Content>(_ content: Message, endpoint: String, domain domainConfig: DomainConfig, on container: Container) throws -> Future<Response> {
        let authKeyEncoded = try encode(apiKey: self.apiKey)
        
        var headers = HTTPHeaders([])
        headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
        
        let mailgunURL = "\(self.baseApiUrl(for: domainConfig))/\(domainConfig.domain)/\(endpoint)"
        
        let client = try container.make(Client.self)
        
        return client.post(mailgunURL, headers: headers) { req in
            try req.content.encode(content)
        }.map { response in
            try self.process(response)
        }
    }
    
}

// MARK: - Conversions

extension Array where Element == Mailgun.Message.FullEmail {
    
    var stringArray: [String] {
        return map { entry -> String in
            guard let name = entry.name else {
                return entry.email
            }
            return "\"\(name) <\(entry.email)>\""
        }
    }
}
