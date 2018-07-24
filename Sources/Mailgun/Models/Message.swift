import Vapor

extension Mailgun {
    public struct Message: Content {
        public static var defaultContentType: MediaType = MediaType.formData
        
        public typealias FullEmail = (email: String, name: String?)
        
        public let from: String
        public let to: String
        public let cc: String?
        public let bcc: String?
        public let subject: String
        public let text: String
        public let html: String?
        public let attachment: [File]?
        
        public init(from: String, to: String, cc: String? = nil, bcc: String? = nil, subject: String, text: String, html: String? = nil, attachments: [File]? = nil) {
            self.from = from
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.subject = subject
            self.text = text
            self.html = html
            self.attachment = attachments
        }
        
        public init(from: String, to: [String], cc: [String]? = nil, bcc: [String]? = nil, subject: String, text: String, html: String? = nil, attachments: [File]? = nil) {
            self.from = from
            self.to = to.joined(separator: ",")
            self.cc = cc?.joined(separator: ",")
            self.bcc = bcc?.joined(separator: ",")
            self.subject = subject
            self.text = text
            self.html = html
            self.attachment = attachments
        }
        
        public init(from: String, to: [FullEmail], cc: [FullEmail]? = nil, bcc: [FullEmail]? = nil, subject: String, text: String, html: String? = nil, attachments: [File]? = nil) {
            self.from = from
            self.to = to.stringArray.joined(separator: ",")
            self.cc = cc?.stringArray.joined(separator: ",")
            self.bcc = bcc?.stringArray.joined(separator: ",")
            self.subject = subject
            self.text = text
            self.html = html
            self.attachment = attachments
        }
    }
}

