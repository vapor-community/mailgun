import Vapor
import Crypto

public struct MailgunFormData: Content {
    public static let defaultMediaType: MediaType = MediaType.urlEncodedForm
    
    let from: String
    let to: String
    let subject: String
    let text: String
}

public protocol Mailgun: class, Service {
    var apiKey: String { get }
    var customURL: String { get }
    func sendMail(data content: MailgunFormData, on req: Request) throws -> Future<Response>
}

public class MailgunEngine: Mailgun {
    public var apiKey: String
    public var customURL: String
    
    public init(apiKey: String, customURL: String) {
        self.apiKey = apiKey
        self.customURL = customURL
    }
    
    public func sendMail(data content: MailgunFormData, on req: Request) throws -> Future<Response> {
        let client = try req.make(EngineClient.self)
        let encode: (String) -> String = Base64Encoder(encoding: .base64).encode
        let authKey = encode("api:key-\(self.apiKey)")
        
        let headers = HTTPHeaders(dictionaryLiteral:
            (HTTPHeaderName.authorization, "Basic \(authKey)"),
                                  (HTTPHeaderName.contentType, "application/x-www-form-urlencoded")
        )
        
        let mailgunURL = "https://api.mailgun.net/v3/\(self.customURL)/messages"
        
        
        return client
            .post(mailgunURL, headers: headers, content: content)
            .map(to: Response.self) { (response) in
                return response
            }.catch { (err) in
                print(err)
        }
    }
}
