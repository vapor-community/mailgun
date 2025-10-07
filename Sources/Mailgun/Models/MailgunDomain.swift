public struct MailgunDomain: Sendable {
    public let domain: String
    public let region: MailgunRegion

    public init(_ domain: String, _ region: MailgunRegion) {
        self.domain = domain
        self.region = region
    }
}

/// Describes a region: US or EU
public enum MailgunRegion: String, Sendable {
    case us
    case eu
}
