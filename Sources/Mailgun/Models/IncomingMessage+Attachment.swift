import Foundation

extension IncomingMailgun {
    public struct Attachment: Codable {
        public let size: Int64
        public let url, name, contentType: String
        
        enum CodingKeys: String, CodingKey {
            case size, url, name
            case contentType = "content-type"
        }
    }
}
