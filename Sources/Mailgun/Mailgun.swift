import Vapor
import Foundation


// MARK: - Service

public protocol MailgunProvider: Service {
    var apiKey: String { get }
    var domain: String { get }
    func send(_ content: Mailgun.Message, on container: Container) throws -> Future<Response>
    func setupForwarding(setup: RouteSetup, with container: Container) throws -> Future<Response>
}

// MARK: - Engine

public struct Mailgun: MailgunProvider {
    
    public enum MailgunError: Error {
        case encodingProblem
        case authenticationFailed
        case unableToSendEmail
    }
    
    public let apiKey: String
    public let domain: String
    
    // MARK: Initialization
    
    public init(apiKey: String, domain: String) {
        self.apiKey = apiKey
        self.domain = domain
    }
    
    // MARK: Send message
    
    public func send(_ content: Message, on container: Container) throws -> Future<Response> {
        let authKeyEncoded = try encode(apiKey: self.apiKey)
        
        var headers = HTTPHeaders([])
        headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
        
        let mailgunURL = "https://api.mailgun.net/v3/\(domain)/messages"
        
        let client = try container.make(Client.self)
        
        return client.post(mailgunURL, headers: headers) { req in
            try req.content.encode(content)
        }.map(to: Response.self) { response in
            switch true {
            case response.http.status.code == HTTPStatus.ok.code:
                return response
            case response.http.status.code == HTTPStatus.unauthorized.code:
                throw MailgunError.authenticationFailed
            default:
                throw MailgunError.unableToSendEmail
            }
        }
    }
    
    public func setupForwarding(setup: RouteSetup, with container: Container) throws -> Future<Response> {
        let authKeyEncoded = try encode(apiKey: self.apiKey)
        
        var headers = HTTPHeaders([])
        headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
        
        let mailgunURL = "https://api.mailgun.net/v3/routes"
        
        let client = try container.make(Client.self)
        
        return client.post(mailgunURL, headers: headers) { req in
                try req.content.encode(setup)
            }.map(to: Response.self) { (response) in
                switch true {
                case response.http.status.code == HTTPStatus.ok.code:
                    return response
                case response.http.status.code == HTTPStatus.unauthorized.code:
                    throw MailgunError.authenticationFailed
                default:
                    throw MailgunError.unableToSendEmail
                }
            }
    }
    
}

// MARK: Private

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
}

// MARK: - Conversions

extension Array where Element == Mailgun.Message.FullEmail {
    
    var stringArray: [String] {
        return map({ entry -> String in
            guard let name = entry.name else {
                return entry.email
            }
            return "\"\(name) <\(entry.email)>\""
        })
    }
}
