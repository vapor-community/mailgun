import Vapor

extension Mailgun {
    func postRequest<Message: Content>(_ content: Message, endpoint: String) -> EventLoopFuture<ClientResponse> {
        guard let configuration = self.storage.configuration else {
            fatalError("Mailgun not configured. Use app.mailgun.configuration = ...")
        }
        
        return application.eventLoopGroup.future().flatMapThrowing { _ -> HTTPHeaders in
            let authKeyEncoded = try self.encode(apiKey: configuration.apiKey)
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Basic \(authKeyEncoded)")
            return headers
        }.flatMap { headers in
            let mailgunURI = URI(string: "\(self.baseApiUrl)/\(self.domain.domain)/\(endpoint)")
            return self.application.client.post(mailgunURI, headers: headers) { req in
                try req.content.encode(content)
            }.flatMapThrowing {
                try self.parse(response: $0)
            }
        }
    }
}
