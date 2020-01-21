import Vapor

public struct MailgunIncomingMessage: Content {
    public static var defaultContentType: HTTPMediaType = .formData
    
    public let recipients: String
    public let sender: String
    public let from: String
    public let subject: String
    public let bodyPlain: String
    public let strippedText: String
    public let strippedSignature: String?
    public let bodyHTML: String
    public let strippedHTML: String
    public let messageHeaders: String
    public let contentIdMap: String
    public let attachments: [Attachment]?
    
    enum CodingKeys: String, CodingKey {
        case recipients
        case sender
        case from
        case subject
        case bodyPlain = "body-plain"
        case strippedText = "stripped-text"
        case strippedSignature = "stripped-signiture"
        case bodyHTML = "body-html"
        case strippedHTML = "stripped-html"
        case messageHeaders = "message-headers"
        case contentIdMap = "content-id-map"
        case attachments
    }
}

extension MailgunIncomingMessage {
    public struct Attachment: Codable {
        public let size: Int64
        public let url: String
        public let name: String
        public let contentType: String
        
        enum CodingKeys: String, CodingKey {
            case size
            case url
            case name
            case contentType = "content-type"
        }
    }
}
