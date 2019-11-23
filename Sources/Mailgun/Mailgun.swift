import Vapor
import Foundation


// MARK: - Service

public protocol MailgunProvider: Service {
    var apiKey: String { get }
    var domains: [Mailgun.DomainConfig] { get }
    func send(_ content: Mailgun.Message, domain: String?, on container: Container) throws -> Future<Response>
    func send(_ content: Mailgun.TemplateMessage, domain: String?, on container: Container) throws -> Future<Response>
    func setup(forwarding: RouteSetup, domain: String?, with container: Container) throws -> Future<Response>
    func createTemplate(_ template: Mailgun.Template, domain: String?, on container: Container) throws -> Future<Response>
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

        // The passed domain is not found in the config
        case domainNotFound

        // No domains where passed to the initializer
        case noDomainsConfigured
        
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
            case .domainNotFound:
                return "mailgun.domain_not_found"
            case .noDomainsConfigured:
                return "mailgun.no_domains_configured"
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
            case .domainNotFound:
                return "Passed domain wasn't found in the config"
            case .noDomainsConfigured:
                return "No domains where configured"
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
    
    /// DomainConfigs
    public let domains: [DomainConfig]


    // MARK: Initialization
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - domain: API domain
    public init(apiKey: String, domain: String, region: Mailgun.Region) {
        self.apiKey = apiKey
        self.domains = [Mailgun.DomainConfig(domain, region: region)]
    }

    /// Initializer
    ///
    /// - Parameters:
    ///   - apiKey: API key including "key-" prefix
    ///   - domains: DomainConfigs - Mailgun.DomainConfig("example.com", region: .na)
    public init(apiKey: String, domains: [Mailgun.DomainConfig]) throws {
        self.apiKey = apiKey

        guard domains.count > 0 else {
            throw Error.noDomainsConfigured
        }

        self.domains = domains
    }
    
    // MARK: Send message
    
    /// Send message
    ///
    /// - Parameters:
    ///   - content: Message
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: Message, domain: String? = nil, on container: Container) throws -> Future<Response> {
        return try postRequest(content, endpoint: "messages", domain: domain, on: container)
    }

    // MARK: Send message
    
    /// Send message
    ///
    /// - Parameters:
    ///   - content: TemplateMessage
    ///   - container: Container
    /// - Returns: Future<Response>
    public func send(_ content: TemplateMessage, domain: String? = nil, on container: Container) throws -> Future<Response> {
        return try postRequest(content, endpoint: "messages", domain: domain, on: container)
    }
    
    /// Setup forwarding
    ///
    /// - Parameters:
    ///   - setup: RouteSetup
    ///   - container: Container
    /// - Returns: Future<Response>
    public func setup(forwarding setup: RouteSetup, domain: String? = nil, with container: Container) throws -> Future<Response> {
        return try postRequest(setup, endpoint: "v3/routes", domain: domain, on: container)
    }

    /// Create template
    ///
    /// - Parameters:
    ///   - template: Template
    ///   - container: Container
    /// - Returns: Future<Response>
    public func createTemplate(_ template: Template, domain: String? = nil, on container: Container) throws -> Future<Response> {
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

    private func postRequest<Message: Content>(_ content: Message, endpoint: String, domain: String? = nil, on container: Container) throws -> Future<Response> {
        let authKeyEncoded = try encode(apiKey: self.apiKey)
        
        var headers = HTTPHeaders([])
        headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
        
        let dc: DomainConfig? = domain != nil ? self.domains.filter { $0.domain == domain }.first : self.domains.first

        guard let domainConfig = dc else {
            throw Error.domainNotFound 
        }

        let mailgunURL = "\(self.baseApiUrl(for: domainConfig ))/\(domainConfig.domain)/\(endpoint)"
        
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
