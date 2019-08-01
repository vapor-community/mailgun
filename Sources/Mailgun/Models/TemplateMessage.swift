import Vapor

extension Mailgun {
    public struct TemplateMessage: Content {
        public static var defaultContentType: MediaType = MediaType.formData
        
        public typealias FullEmail = (email: String, name: String?)
        
        public let from: String
        public let to: String
        public let replyTo: String?
        public let cc: String?
        public let bcc: String?
        public let subject: String
        public let template: String
        public let templateData: [String:String]?
        public let templateVersion: String?
        public let templateText: Bool?
        public let attachment: [File]?
        public let inline: [File]?
        
        private enum CodingKeys : String, CodingKey {
            case from, to, replyTo = "h:Reply-To", cc, bcc, subject, template, templateData = "h:X-Mailgun-Variables", templateVersion = "t:version", templateText = "t:text", attachment, inline
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
            try container.encode(cc, forKey: .cc)
            try container.encode(bcc, forKey: .bcc)            
            try container.encode(subject, forKey: .subject)
            try container.encode(template, forKey: .template)
            let jsonData = try! JSONEncoder().encode(templateData)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            try container.encode(jsonString, forKey: .templateData)
            try container.encode(templateVersion, forKey: .templateVersion)
            let text = templateText != nil && templateText! ? "yes" : nil // need to send yes as string
            try container.encode(text, forKey: .templateText)
            try container.encode(attachment, forKey: .attachment)
            try container.encode(inline, forKey: .inline)
        }
        
        public init(from: String, to: String, replyTo: String? = nil, cc: String? = nil, bcc: String? = nil, subject: String, template: String, templateData: [String:String]? = nil, templateVersion: String? = nil, templateText: Bool? = nil, attachments: [File]? = nil, inline: [File]? = nil) {
            self.from = from
            self.to = to
            self.replyTo = replyTo
            self.cc = cc
            self.bcc = bcc
            self.subject = subject
            self.template = template
            self.templateData = templateData
            self.templateVersion = templateVersion
            self.templateText = templateText
            self.attachment = attachments
            self.inline = inline
        }
        
        public init(from: String, to: [String], replyTo: String? = nil, cc: [String]? = nil, bcc: [String]? = nil, subject: String, template: String, templateData: [String:String]? = nil,  templateVersion: String? = nil, templateText: Bool? = nil, attachments: [File]? = nil, inline: [File]? = nil) {
            self.from = from
            self.to = to.joined(separator: ",")
            self.replyTo = replyTo
            self.cc = cc?.joined(separator: ",")
            self.bcc = bcc?.joined(separator: ",")
            self.subject = subject
            self.template = template
            self.templateData = templateData
            self.templateVersion = templateVersion
            self.templateText = templateText
            self.attachment = attachments
            self.inline = inline
        }
        
        public init(from: String, to: [FullEmail], replyTo: String? = nil, cc: [FullEmail]? = nil, bcc: [FullEmail]? = nil, subject: String, template: String, templateData: [String:String]? = nil, templateVersion: String? = nil, templateText: Bool? = nil, attachments: [File]? = nil, inline: [File]? = nil) {
            self.from = from
            self.to = to.stringArray.joined(separator: ",")
            self.replyTo = replyTo
            self.cc = cc?.stringArray.joined(separator: ",")
            self.bcc = bcc?.stringArray.joined(separator: ",")
            self.subject = subject
            self.template = template
            self.templateData = templateData
            self.templateVersion = templateVersion
            self.templateText = templateText
            self.attachment = attachments
            self.inline = inline
        }
    }
}