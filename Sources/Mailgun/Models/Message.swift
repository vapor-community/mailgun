import Vapor

extension Mailgun {
    public enum HTMLView {
        case raw(String)
        case leaf(Future<View>)
    }
    
    public struct Message: Content {
        public static var defaultContentType: MediaType = MediaType.formData
        
        public typealias FullEmail = (email: String, name: String?)
        
        public let from: String
        public let to: String
        public let replyTo: String?
        public let cc: String?
        public let bcc: String?
        public let subject: String
        public let text: String
        public let htmlString: String?
        public let html: HTMLView?
        public let attachment: [File]?
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
            try container.encode(replyTo, forKey: .replyTo)
            try container.encode(cc, forKey: .cc)
            try container.encode(bcc, forKey: .bcc)
            try container.encode(subject, forKey: .subject)
            try container.encode(text, forKey: .from)
            try container.encode(htmlString, forKey: .htmlString)
            try container.encode(attachment, forKey: .attachment)
        }
        
        public init(from decoder: Decoder) throws {
            fatalError()
        }
        
        private enum CodingKeys : String, CodingKey {
            case from, to, replyTo = "h:Reply-To", cc, bcc, subject, text, htmlString, attachment
        }
        
        public init(
            from: String,
            to: String,
            replyTo: String? = nil,
            cc: String? = nil,
            bcc: String? = nil,
            subject: String,
            text: String,
            html: HTMLView? = nil,
            attachments: [File]? = nil
        ) {
            self.from = from
            self.to = to
            self.replyTo = replyTo
            self.cc = cc
            self.bcc = bcc
            self.subject = subject
            self.text = text
            self.html = html
            self.htmlString = nil
            self.attachment = attachments
        }
        
        public init(
            from: String,
            to: [String],
            replyTo: String? = nil,
            cc: [String]? = nil,
            bcc: [String]? = nil,
            subject: String,
            text: String,
            html: HTMLView? = nil,
            attachments: [File]? = nil
        ) {
            self.from = from
            self.to = to.joined(separator: ",")
            self.replyTo = replyTo
            self.cc = cc?.joined(separator: ",")
            self.bcc = bcc?.joined(separator: ",")
            self.subject = subject
            self.text = text
            self.html = html
            self.htmlString = nil
            self.attachment = attachments
        }
        
        public init(
            from: String,
            to: [FullEmail],
            replyTo: String? = nil,
            cc: [FullEmail]? = nil,
            bcc: [FullEmail]? = nil,
            subject: String,
            text: String,
            html: HTMLView? = nil,
            attachments: [File]? = nil
        ) {
            self.from = from
            self.to = to.stringArray.joined(separator: ",")
            self.replyTo = replyTo
            self.cc = cc?.stringArray.joined(separator: ",")
            self.bcc = bcc?.stringArray.joined(separator: ",")
            self.subject = subject
            self.text = text
            self.html = html
            self.htmlString = nil
            self.attachment = attachments
        }
        
        fileprivate init(
            from: String,
            to: String,
            replyTo: String? = nil,
            cc: String? = nil,
            bcc: String? = nil,
            subject: String,
            text: String,
            htmlString: String? = nil,
            attachments: [File]? = nil
        ) {
            self.from = from
            self.to = to
            self.replyTo = replyTo
            self.cc = cc
            self.bcc = bcc
            self.subject = subject
            self.text = text
            self.html = nil
            self.htmlString = htmlString
            self.attachment = attachments
        }
    }
}

extension Mailgun.Message: ResponseEncodable {
    public func encode(for req: Request) throws -> EventLoopFuture<Response> {
        if let html = self.html {
            switch html {
            case .raw(let htmlString):
                let message = Mailgun.Message.init(
                    from: self.from,
                    to: self.to,
                    replyTo: self.replyTo,
                    cc: self.cc,
                    bcc: self.bcc,
                    subject: self.subject,
                    text: self.text,
                    htmlString: htmlString,
                    attachments: self.attachment
                )
                
                return try message.encode(for: req)
            case .leaf(let htmlFuture):
                return htmlFuture.flatMap { htmlData in
                    let htmlString = String(data: htmlData.data, encoding: .utf8)
                    let message = Mailgun.Message.init(
                        from: self.from,
                        to: self.to,
                        replyTo: self.replyTo,
                        cc: self.cc,
                        bcc: self.bcc,
                        subject: self.subject,
                        text: self.text,
                        htmlString: htmlString,
                        attachments: self.attachment
                    )
                    
                    return try message.encode(for: req)
                }
            }
        } else {
            return try self.encode(for: req)
        }
    }
}

