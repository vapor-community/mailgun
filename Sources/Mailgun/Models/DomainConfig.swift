import Vapor

extension Mailgun {
    /// Config for a Domain (to register multiple in one service)
    public struct DomainConfig {
        let domain: String
        let region: Mailgun.Region
        
        public init(_ domain: String, region: Mailgun.Region) {
            self.domain = domain
            self.region = region
        }
    }
}