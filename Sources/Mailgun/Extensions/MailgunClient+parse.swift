import Vapor

extension MailgunClient {
    func parse(response: ClientResponse) throws -> ClientResponse {
        switch true {
        case response.status == .ok:
            return response
        case response.status == .unauthorized:
            throw MailgunError.authenticationFailed
        default:
            if let body = response.body, let err = try? JSONDecoder().decode(MailgunErrorResponse.self, from: body) {
                if err.message.hasPrefix("template") {
                    throw MailgunError.unableToCreateTemplate(err)
                } else {
                    throw MailgunError.unableToSendEmail(err)
                }
            }
            throw MailgunError.unknownError(response)
        }
    }
}
