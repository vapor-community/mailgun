import Foundation
import Vapor

// MARK: - Service
public protocol MailgunProvider: Sendable {
    @discardableResult func send(_ content: MailgunMessage) async throws -> ClientResponse
    @discardableResult func send(_ content: MailgunTemplateMessage) async throws -> ClientResponse
    @discardableResult func setup(forwarding: MailgunRouteSetup) async throws -> ClientResponse
    @discardableResult func createTemplate(_ template: MailgunTemplate) async throws -> ClientResponse
}

public struct MailgunClient: MailgunProvider {
    let apiKey: String
    let domain: MailgunDomain
    let client: Client
}

// MARK: - Send message

extension MailgunClient {
    /// Base API URL based on the current region
    var baseApiUrl: String {
        switch domain.region {
        case .us: "https://api.mailgun.net/v3"
        case .eu: "https://api.eu.mailgun.net/v3"
        }
    }

    /// Send message
    ///
    /// - Parameter content: Message
    public func send(_ content: MailgunMessage) async throws -> ClientResponse {
        try await postRequest(content, endpoint: "messages")
    }

    /// Send message
    ///
    /// - Parameter content: TemplateMessage
    public func send(_ content: MailgunTemplateMessage) async throws -> ClientResponse {
        try await postRequest(content, endpoint: "messages")
    }

    /// Setup forwarding
    public func setup(forwarding setup: MailgunRouteSetup) async throws -> ClientResponse {
        try await postRequest(setup, endpoint: "v3/routes")
    }

    /// Create template
    public func createTemplate(_ template: MailgunTemplate) async throws -> ClientResponse {
        try await postRequest(template, endpoint: "templates")
    }
}
