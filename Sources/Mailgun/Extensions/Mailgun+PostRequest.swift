import Vapor
import AsyncHTTPClient

extension MailgunClient {
    func postRequest<Message: Content>(_ content: Message, endpoint: String) -> EventLoopFuture<HTTPClient.Response> {
        do {
            let authKeyEncoded = try self.encode(apiKey: config.apiKey)
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Basic \(authKeyEncoded)")
            headers.add(name: .contentType, value: "multipart/form-data")
            
            let mailgunURI = "\(self.baseApiUrl)/\(self.domain.domain)/\(endpoint)"
            
            var byteBuffer = ByteBuffer(.init())
            
            try FormDataEncoder().encode(content, to: &byteBuffer, headers: &headers)
            
            let request = try HTTPClient.Request(url: mailgunURI, method: .POST, headers: headers, body: .byteBuffer(byteBuffer))
            
            return self.client.execute(request: request, eventLoop: .delegate(on: self.eventLoop)).flatMapThrowing {
                try self.parse(response: $0)
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
