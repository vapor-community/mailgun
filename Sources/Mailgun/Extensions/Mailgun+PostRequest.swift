import Vapor
import AsyncHTTPClient

extension MailgunClient {
    func postRequest<Message: Content>(_ content: Message, endpoint: String) -> EventLoopFuture<HTTPClient.Response> {
        do {
            let authKeyEncoded = try self.encode(apiKey: config.apiKey)
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Basic \(authKeyEncoded)")
            
            let mailgunURI = "\(self.baseApiUrl)/\(self.domain.domain)/\(endpoint)"
            
            let request = try HTTPClient.Request(url: mailgunURI, method: .POST, headers: headers, body: .data(JSONEncoder().encode(content)))
            
            return self.client.execute(request: request, eventLoop: .delegate(on: self.eventLoop)).flatMapThrowing {
                try self.parse(response: $0)
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
