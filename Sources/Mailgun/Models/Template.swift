import Vapor

/// Template, see https://documentation.mailgun.com/en/latest/api-templates.html#templates
public struct MailgunTemplate: Content {
    public static var defaultContentType: HTTPMediaType = .formData

    public let name: String
    public let description: String
    public let template: String?
    public let tag: String?
    public let engine: String?
    public let versionComment: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case template
        case tag
        case engine
        case versionComment = "comment"
    }
    
    public init(name: String, description: String, template: String? = nil, tag: String? = nil, engine: String? = nil, versionComment: String? = nil) {
        self.name = name
        self.description = description
        self.template = template
        self.tag = tag
        self.engine = engine
        self.versionComment = versionComment
    }
}

