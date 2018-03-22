import Vapor
import Foundation

public protocol MailgunProvider: Service {
    var apiKey: String { get }
    var customURL: String { get }
    func sendMail(data content: MailgunEngine.FormData, on req: Request) throws -> Future<Response>
}

public struct MailgunEngine: MailgunProvider {
    
    public enum MailgunError: Error {
        case encodingProblem
    }
    
    public struct FormData: Content {
        public static let defaultMediaType: MediaType = MediaType.urlEncodedForm
        
        let from: String
        let to: String
        let subject: String
        let text: String
        
        public init(from: String, to: String, subject: String, text: String) {
            self.from = from
            self.to = to
            self.subject = subject
            self.text = text
        }
    }
    
    public var apiKey: String
    public var customURL: String
    
    public init(apiKey: String, customURL: String) {
        self.apiKey = apiKey
        self.customURL = customURL
    }
    
    public func sendMail(data content: FormData, on req: Request) throws -> Future<Response> {
        guard let apiKeyData = "api:key-\(self.apiKey)".data(using: .utf8) else {
            throw MailgunError.encodingProblem
        }
        let authKey = apiKeyData.base64EncodedData()
        guard let authKeyEncoded = String.init(data: authKey, encoding: .utf8) else {
            throw MailgunError.encodingProblem
        }
        
        var headers = HTTPHeaders([])
        headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
        headers.add(name: HTTPHeaderName.contentType, value: "application/x-www-form-urlencoded")
        
        let mailgunURL = "https://api.mailgun.net/v3/\(self.customURL)/messages"
        
        let client = try req.make(Client.self)
        return client
            .post(mailgunURL, headers: headers, content: content)
            .map(to: Response.self) { (response) in
                return response
        }
    }
}
