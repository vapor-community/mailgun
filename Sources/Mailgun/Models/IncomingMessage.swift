import Vapor

public struct IncomingMailgun: Content {
    public static var defaultMediaType: MediaType = MediaType.formData
    
    public let recipient: String
    public let sender: String
    public let from: String
    public let subject: String
    public let bodyPlain: String
    public let strippedText: String
    public let strippedSignature: String?
    public let bodyHTML: String
    public let strippedHTML: String
    public let attachmentCount: Int
    public let timestamp: Int
    public let token: String
    public let signature: String
    public let messageHeaders: String
    public let contentIdMap: String
    public let attachment: String?
    
    enum CodingKeys: String, CodingKey {
        case recipient
        case sender
        case from
        case subject
        case bodyPlain = "body-plain"
        case strippedText = "stripped-text"
        case strippedSignature = "stripped-signiture"
        case bodyHTML = "body-html"
        case strippedHTML = "stripped-html"
        case attachmentCount = "attachment-count"
        case timestamp
        case token
        case signature
        case messageHeaders = "message-headers"
        case contentIdMap = "content-id-map"
        case attachment = "attachment-x"
    }
}
