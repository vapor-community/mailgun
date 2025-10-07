public import Vapor

/// Mailgun error type.
public struct MailgunError: Error, Sendable, Equatable {
    public struct ErrorType: Sendable, Hashable, CustomStringConvertible, Equatable {
        enum Base: String, Sendable, Equatable {
            case encodingProblem
            case authenticationFailed
            case unableToSendEmail
            case unableToCreateTemplate
            case unknownError
        }

        let base: Base

        private init(_ base: Base) {
            self.base = base
        }

        public static let encodingProblem = Self(.encodingProblem)
        public static let authenticationFailed = Self(.authenticationFailed)
        public static let unableToSendEmail = Self(.unableToSendEmail)
        public static let unableToCreateTemplate = Self(.unableToCreateTemplate)
        public static let unknownError = Self(.unknownError)

        public var description: String {
            base.rawValue
        }
    }

    private struct Backing: Sendable, Equatable {
        fileprivate let errorType: ErrorType
        fileprivate let mailgunErrorResponse: MailgunErrorResponse?
        fileprivate let clientResponse: ClientResponse?

        init(
            errorType: ErrorType,
            mailgunErrorResponse: MailgunErrorResponse? = nil,
            clientResponse: ClientResponse? = nil
        ) {
            self.errorType = errorType
            self.mailgunErrorResponse = mailgunErrorResponse
            self.clientResponse = clientResponse
        }

        static func == (lhs: Backing, rhs: Backing) -> Bool {
            lhs.errorType == rhs.errorType
        }
    }

    private var backing: Backing

    public var errorType: ErrorType { backing.errorType }
    public var mailgunErrorResponse: MailgunErrorResponse? { backing.mailgunErrorResponse }
    public var clientResponse: ClientResponse? { backing.clientResponse }

    private init(backing: Backing) {
        self.backing = backing
    }

    private init(errorType: ErrorType) {
        self.backing = .init(errorType: errorType)
    }

    /// Encoding problem
    public static let encodingProblem = Self(errorType: .encodingProblem)

    /// Failed authentication
    public static let authenticationFailed = Self(errorType: .authenticationFailed)

    /// Failed to send email (with error message)
    public static func unableToSendEmail(_ error: MailgunErrorResponse) -> Self {
        .init(backing: .init(errorType: .unableToSendEmail, mailgunErrorResponse: error))
    }

    /// Failed to create template (with error message)
    public static func unableToCreateTemplate(_ error: MailgunErrorResponse) -> Self {
        .init(backing: .init(errorType: .unableToCreateTemplate, mailgunErrorResponse: error))
    }

    /// Generic error
    public static func unknownError(_ response: ClientResponse) -> Self {
        .init(backing: .init(errorType: .unknownError, clientResponse: response))
    }
}

extension MailgunError: CustomStringConvertible {
    public var description: String {
        var result = "MailgunError(errorType: \(self.errorType)"

        if let mailgunErrorResponse {
            result += ", mailgunErrorResponse: \(String(reflecting: mailgunErrorResponse))"
        }

        if let clientResponse {
            result += ", clientResponse: \(String(reflecting: clientResponse))"
        }

        result += ")"
        return result
    }
}
