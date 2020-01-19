public struct MailgunDomain {
    public let domain: String
    public let region: MailgunRegion
    
    public init(_ domain: String, _ region: MailgunRegion) {
        self.domain = domain
        self.region = region
    }
}
