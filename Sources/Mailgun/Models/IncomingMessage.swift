import Vapor

public struct IncomingMailgun: Content {
    public static var defaultContentType: MediaType = MediaType.formData
    
    public let recipients: String
    public let sender: String
    public let from: String
    public let subject: String
    public let bodyPlain: String
    public let strippedText: String
    public let strippedSignature: String?
    public let bodyHTML: String
    public let strippedHTML: String
    public let attachments: [Attachment]?
    public let messageHeaders: String
    public let contentIdMap: String
    
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
        case attachments
        case messageHeaders = "message-headers"
        case contentIdMap = "content-id-map"
    }
}
