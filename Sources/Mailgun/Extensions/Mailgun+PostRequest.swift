import Vapor
import AsyncHTTPClient

extension MailgunClient {
    func postRequest<Message: Content>(_ content: Message, endpoint: String) -> EventLoopFuture<ClientResponse> {
        do {
            let authKeyEncoded = try self.encode(apiKey: config.apiKey)
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Basic \(authKeyEncoded)")

            let mailgunURI = URI(string: "\(self.baseApiUrl)/\(self.domain.domain)/\(endpoint)")
            
            return self.client.post(mailgunURI, headers: headers, beforeSend: { req in
                try req.content.encode(content)
            }).flatMapThrowing {
                try self.parse(response: $0)
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
