import Vapor

protocol CurlDebugConvertible {
    var cURLRepresentation: String { get }
}

extension HTTPRequest: CurlDebugConvertible {
    /// The textual representation used when written to an output stream, in the form of a cURL command.
    public var cURLRepresentation: String {
        var components = ["$ curl -i"]
        let host = url.host
        let httpMethod = self.method
        
        if httpMethod != .GET {
            components.append("-X \(httpMethod)")
        }
        
        var headers: [AnyHashable: Any] = [:]
        
        
        for (field, value) in self.headers {
            headers[field] = value
        }
        
        for (field, value) in headers {
            components.append("-H \"\(field): \(value)\"")
        }
        let httpBody = self.body.description
        
        var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
        escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
        
        components.append("-d \"\(escapedBody)\"")
        
        components.append("\"\(url.absoluteString)\"")
        
        return components.joined(separator: " \\\n\t")
    }
}
