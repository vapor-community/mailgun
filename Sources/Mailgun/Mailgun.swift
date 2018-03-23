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
    
    public enum Problem: Error {
        case encodingProblem
        case authenticationFailed
        case unableToSendEmail
    }
    
    public struct Message: Content {
        
        public typealias FullEmail = (email: String, name: String?)
        
        public let from: String
        public let to: String
        public let cc: String?
        public let bcc: String?
        public let subject: String
        public let text: String
        public let html: String?
        
        public init(from: String, to: String, cc: String? = nil, bcc: String? = nil, subject: String, text: String, html: String? = nil, attachment: [Data] = []) {
            self.from = from
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.subject = subject
            self.text = text
            self.html = html
        }
        
        public init(from: String, to: [String], cc: [String]? = nil, bcc: [String]? = nil, subject: String, text: String, html: String? = nil, attachment: [Data] = []) {
            self.from = from
            self.to = to.joined(separator: ",")
            self.cc = cc?.joined(separator: ",")
            self.bcc = bcc?.joined(separator: ",")
            self.subject = subject
            self.text = text
            self.html = html
        }
        
        public init(from: String, to: [FullEmail], cc: [FullEmail]? = nil, bcc: [FullEmail]? = nil, subject: String, text: String, html: String? = nil, attachment: [Data] = []) {
            self.from = from
            self.to = to.stringArray.joined(separator: ",")
            self.cc = cc?.stringArray.joined(separator: ",")
            self.bcc = bcc?.stringArray.joined(separator: ",")
            self.subject = subject
            self.text = text
            self.html = html
        }
        
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
            throw Problem.encodingProblem
        }
        let authKey = apiKeyData.base64EncodedData()
        guard let authKeyEncoded = String.init(data: authKey, encoding: .utf8) else {
            throw Problem.encodingProblem
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
                throw Problem.authenticationFailed
            default:
                throw Problem.unableToSendEmail
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
