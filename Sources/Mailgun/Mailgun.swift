import Vapor
import Foundation


// MARK: - Service

public protocol MailgunProvider: Service {
    var apiKey: String { get }
    var domain: String { get }
    func send(_ content: Mailgun.Message, on req: Request) throws -> Future<Response>
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
    
    public func send(_ content: Message, on req: Request) throws -> Future<Response> {
        let key = apiKey.contains("key-") ? apiKey : "key-\(apiKey)"
        guard let apiKeyData = "api:\(key)".data(using: .utf8) else {
            throw MailgunError.encodingProblem
        }
        let authKey = apiKeyData.base64EncodedData()
        guard let authKeyEncoded = String.init(data: authKey, encoding: .utf8) else {
            throw MailgunError.encodingProblem
        }
        
        var headers = HTTPHeaders([])
        headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
        let contentType = MediaType.urlEncodedForm.description
        headers.add(name: HTTPHeaderName.contentType, value: contentType)
        
        let mailgunURL = "https://api.mailgun.net/v3/\(domain)/messages"
        
        let client = try req.make(Client.self)
        
        return client.post(mailgunURL, headers: headers, content: content).map(to: Response.self) { response in
            // can't compare status unless https://github.com/vapor/vapor/issues/1566 is fixed
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
