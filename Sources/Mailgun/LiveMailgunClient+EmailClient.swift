import Vapor
import MailgunKit
import Email
import NIO

public enum VaporMailgunError: Error {
    case failedToSendAttachment(Vapor.File)
}

extension LiveMailgunClient: EmailClient {
    public func send(_ messages: [EmailMessage]) -> EventLoopFuture<Void> {
        do {
            return try messages.map { message -> Mailgun.Message in
                let html: String?
                let text: String?
                
                switch message.content {
                case let .text(_text):
                    text = _text
                    html = nil
                case let .html(_html):
                    html = _html
                    text = nil
                case let .universal(_text, _html):
                    text = _text
                    html = _html
                }
                
                let attachments = try message.attachments?.toMailgunAttachments() ?? []
                let inlines = try message.attachments?.toMailgunInlineAttachments() ?? []
                
                if attachments.count > 1 || inlines.count > 1 {
                    self.logger.warning("Vapor emails for Mailgun does not support multiple attachments, due to limitations with multipart implementation!")
                }
                
                return Mailgun.Message(
                    from: message.from.fullAddress,
                    to: message.to.map(\.mailgun),
                    replyTo: message.replyTo?.fullAddress,
                    cc: message.cc?.map(\.mailgun),
                    bcc: message.bcc?.map(\.mailgun),
                    subject: message.subject,
                    text: text ?? "",
                    html: html,
                    attachments: attachments.first,
                    inline: inlines.first
                )
            }
            .map { self.sendRequest(.send($0)).transform(to: ()) }
            .flatten(on: self.eventLoop)
        } catch {
            return self.eventLoop.future(error: error)
        }
    }
}

extension Collection where Element == EmailAttachment {
    func toMailgunAttachments() throws -> [Mailgun.File] {
        try self.reduce(into: []) { result, attachment in
            guard case let .attachment(file) = attachment else { return }
            return try result.append(file.toMailgunFile())
        }
    }
    
    func toMailgunInlineAttachments() throws -> [Mailgun.File] {
        try self.reduce(into: []) { result, attachment in
            guard case let .inline(file) = attachment else { return }
            return try result.append(file.toMailgunFile())
        }
    }
}

extension Vapor.File {
    func toMailgunFile() throws -> Mailgun.File {
        guard let contentType = self.contentType?.serialize() else {
            throw VaporMailgunError.failedToSendAttachment(self)
        }
        
        return .init(
            data: self.data,
            filename: self.filename,
            contentType: contentType
        )
    }
}

extension EmailAddress {
    var mailgun: Mailgun.FullEmail {
        (self.email, self.name)
    }
}
