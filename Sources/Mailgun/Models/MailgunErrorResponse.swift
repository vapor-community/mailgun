/// Error response object
public struct MailgunErrorResponse: Decodable, Sendable {
    /// Error messsage
    public let message: String
}
