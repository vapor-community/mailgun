import MailgunKit
import Email
import NIO

extension LiveMailgunClient: EmailClient {
    #warning("todo: attachments")
    public func send(_ messages: [EmailMessage]) -> EventLoopFuture<Void> {
        messages.map { message in
            Mailgun.Message(
                from: message.from.fullAddress,
                to: message.to.map(\.mailgun),
                replyTo: message.replyTo?.fullAddress,
                cc: message.cc?.map(\.mailgun),
                bcc: message.bcc?.map(\.mailgun),
                subject: message.subject,
                text: message.content.text ?? "",
                html: message.content.html,
                attachments: [],
                inline: []
            )
        }
        .map { self.sendRequest(.send($0)).transform(to: ()) }
        .flatten(on: self.eventLoop)
    }
}

extension EmailAddress {
    var mailgun: Mailgun.FullEmail {
        (self.email, self.name)
    }
}
