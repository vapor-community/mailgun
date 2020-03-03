import Vapor

public struct MailgunIncomingMessage: Content {
    public static var defaultContentType: HTTPMediaType = .formData
    
    public let recipient: String
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
    public let attachments: [File]
    
    enum CodingKeys: String, CodingKey {
        case recipient
        case sender
        case from
        case subject
        case bodyPlain = "body-plain"
        case strippedText = "stripped-text"
        case strippedSignature = "stripped-signature"
        case bodyHTML = "body-html"
        case strippedHTML = "stripped-html"
        case messageHeaders = "message-headers"
        case contentIdMap = "content-id-map"
        case attachments
    }
    
    struct DynamicAttachmentKey: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            guard stringValue.hasPrefix("attachment-") else { return nil }
            guard let lastKey = stringValue.components(separatedBy: "-").last,
                let _ = Int(lastKey)
                else { return nil}
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipient = try container.decode(String.self, forKey: .recipient)
        sender = try container.decode(String.self, forKey: .sender)
        from = try container.decode(String.self, forKey: .from)
        subject = try container.decode(String.self, forKey: .subject)
        bodyPlain = try container.decode(String.self, forKey: .bodyPlain)
        strippedText = try container.decode(String.self, forKey: .strippedText)
        strippedSignature = try container.decodeIfPresent(String.self, forKey: .strippedSignature)
        bodyHTML = try container.decode(String.self, forKey: .bodyHTML)
        strippedHTML = try container.decode(String.self, forKey: .strippedHTML)
        messageHeaders = try container.decode(String.self, forKey: .messageHeaders)
        contentIdMap = try container.decode(String.self, forKey: .contentIdMap)

        var _attachments: [File] = []
        let attachmentsContainer = try decoder.container(keyedBy: DynamicAttachmentKey.self)
        try attachmentsContainer.allKeys.forEach { attachmentKey in
            _attachments.append(try attachmentsContainer.decode(File.self, forKey: attachmentKey))
        }
        attachments = _attachments
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
