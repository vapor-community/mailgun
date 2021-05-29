import Vapor

public struct MailgunMessage: Content {
    public static var defaultContentType: HTTPMediaType = .formData
    
    public typealias FullEmail = (email: String, name: String?)
    
    public let from: String
    public let to: String
    public let replyTo: String?
    public let cc: String?
    public let bcc: String?
    public let subject: String
    public let text: String
    public let html: String?
    public let attachment: [File]?
    public let inline: [File]?
    
    private enum CodingKeys: String, CodingKey {
        case from
        case to
        case replyTo = "h:Reply-To"
        case cc
        case bcc
        case subject
        case text
        case html
        case attachment
        case inline
    }
    
    public init(from: String, to: String, replyTo: String? = nil, cc: String? = nil, bcc: String? = nil, subject: String, text: String, html: String? = nil, attachments: [File]? = nil, inline: [File]? = nil) {
        self.from = from
        self.to = to
        self.replyTo = replyTo
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.text = text
        self.html = html
        self.attachment = attachments
        self.inline = inline
    }
    
    public init(from: String, to: [String], replyTo: String? = nil, cc: [String]? = nil, bcc: [String]? = nil, subject: String, text: String, html: String? = nil, attachments: [File]? = nil, inline: [File]? = nil) {
        self.from = from
        self.to = to.joined(separator: ",")
        self.replyTo = replyTo
        self.cc = cc?.joined(separator: ",")
        self.bcc = bcc?.joined(separator: ",")
        self.subject = subject
        self.text = text
        self.html = html
        self.attachment = attachments
        self.inline = inline
    }
    
    public init(from: String, to: [FullEmail], replyTo: String? = nil, cc: [FullEmail]? = nil, bcc: [FullEmail]? = nil, subject: String, text: String, html: String? = nil, attachments: [File]? = nil, inline: [File]? = nil) {
        self.from = from
        self.to = to.stringArray.joined(separator: ",")
        self.replyTo = replyTo
        self.cc = cc?.stringArray.joined(separator: ",")
        self.bcc = bcc?.stringArray.joined(separator: ",")
        self.subject = subject
        self.text = text
        self.html = html
        self.attachment = attachments
        self.inline = inline
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
        try container.encode(subject, forKey: .subject)
        try container.encode(text, forKey: .text)
        
        if let replyTo = self.replyTo {
            try container.encode(replyTo, forKey: .replyTo)
        }
        if let cc = self.cc {
            try container.encode(cc, forKey: .cc)
        }
        if let bcc = self.bcc {
            try container.encode(bcc, forKey: .bcc)
        }
        if let html = self.html {
            try container.encode(html, forKey: .html)
        }
        if let inline = self.inline {
            try container.encode(inline, forKey: .inline)
        }
        if let attachments = self.attachment {
            try attachments.forEach { attachment in
                try container.encode(attachment, forKey: .attachment)
            }
        }
    }
}

