<div align="center">
    <img src="https://avatars.githubusercontent.com/u/26165732?s=200&v=4" width="100" height="100" alt="avatar" />
    <h1>Mailgun</h1>
    <a href="https://swiftpackageindex.com/vapor-community/mailgun/documentation">
        <img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
    <a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
    <a href="https://github.com/vapor-community/mailgun/actions/workflows/test.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/vapor-community/mailgun/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration">
    </a>
    <a href="https://codecov.io/github/vapor-community/mailgun">
        <img src="https://img.shields.io/codecov/c/github/vapor-community/mailgun?style=plastic&logo=codecov&label=codecov" alt="Code Coverage">
    </a>
    <a href="https://swift.org">
        <img src="https://design.vapor.codes/images/swift61up.svg" alt="Swift 6.1+">
    </a>
</div>
<br>

`Mailgun` is a Vapor 4 service for the popular [email sending API](https://www.mailgun.com/).

## Usage

Sign up and set up a Mailgun account [here](https://www.mailgun.com/).
Make sure you get an API key and register a custom domain.

### Declare all your domains
```swift
extension MailgunDomain {
    static var myApp1: MailgunDomain { .init("mg.myapp1.com", .us) }
    static var myApp2: MailgunDomain { .init("mg.myapp2.com", .eu) }
    static var myApp3: MailgunDomain { .init("mg.myapp3.com", .us) }
    static var myApp4: MailgunDomain { .init("mg.myapp4.com", .eu) }
}
```

### Configure

In `configure.swift`:

```swift
import Configuration
import Mailgun

public func configure(_ app: Application) async throws {
    // Either set it directly
    app.mailgun.configuration = .init(apiKey: "<api key>", defaultDomain: .myApp1)

    // Or use Swift Configuration to read from environment variables or config files
    let config = ConfigReader(providers: [
        EnvironmentVariablesProvider(),
        try await JSONProvider(filePath: "mailgun.config.json")
    ])
    app.mailgun.configuration = try .init(config: config)
}
```

> Note: If your private API key begins with `key-`, be sure to include it

### Send emails

The `MailgunClient` is available on both `Application` and `Request`

```swift
// Call it without arguments to use default domain
try await app.mailgun.client().send(...)
try await req.mailgunClient().send(...)

// or call it with domain
try await app.mailgun.client(.myApp1).send(...)
try await req.mailgunClient(.myApp1).send(...)
```

> 💡 NOTE: All the examples below will be with `Request`, but you could do the same with `Application` as in example above.

#### Without attachments

```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req async throws -> ClientResponse in
        let message = MailgunMessage(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            text: "This is a newsletter",
            html: "<h1>This is a newsletter</h1>"
        )
        return try await req.mailgunClient().send(message)
    }
}
```

#### With attachments
```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req async throws -> ClientResponse in
        let fm = FileManager.default
        guard let attachmentData = fm.contents(atPath: "/tmp/test.pdf") else {
            throw Abort(.internalServerError)
        }
        let bytes: [UInt8] = Array(attachmentData)
        var bytesBuffer = ByteBufferAllocator().buffer(capacity: bytes.count)
        bytesBuffer.writeBytes(bytes)
        let attachment = File.init(data: bytesBuffer, filename: "test.pdf")
        let message = MailgunMessage(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            text: "This is a newsletter",
            html: "<h1>This is a newsletter</h1>",
            attachments: [attachment]
        )
        return try await req.mailgunClient().send(message)
    }
}
```

#### With template (attachments can be used in same way)
```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req async throws -> ClientResponse in
        let message = MailgunTemplateMessage(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            template: "my-template",
            templateData: ["foo": "bar"]
        )
        return try await req.mailgunClient().send(message)
    }
}
```

#### Setup content through Leaf

Using Vapor Leaf, you can easily setup your HTML Content.

First setup a leaf file in `Resources/Views/Emails/my-email.leaf`

```html
<html>
    <body>
        <p>Hi #(name)</p>
    </body>
</html>
```

With this, you can change the `#(name)` with a variable from your Swift code; then when sending the email:

```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req async throws -> ClientResponse in
        let content = try await req.view.render("Emails/my-email", ["name": "Bob"])

        let message = MailgunMessage(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            text: "",
            html: content
        )

        return try await req.mailgunClient().send(message)
    }
}
```

#### Setup routes
```swift
public func configure(_ app: Application) async throws {
    // sets up a `catch_all` forward for the route listed
    let routeSetup = MailgunRouteSetup(forwardURL: "http://example.com/mailgun/all", description: "A route for all emails")
    try await app.mailgun.client().setup(forwarding: routeSetup)
}
```

#### Handle routes
```swift
import Mailgun

func routes(_ app: Application) throws {
    let mailgunGroup = app.grouped("mailgun")
    mailgunGroup.post("all") { req -> String in
        do {
            let incomingMail = try req.content.decode(MailgunIncomingMessage.self)
            print("incomingMail: (incomingMail)")
            return "Hello"
        } catch {
            throw Abort(.internalServerError, reason: "Could not decode incoming message")
        }
    }
}
```

#### Creating templates
```swift
import Mailgun

func routes(_ app: Application) throws {
    let mailgunGroup = app.grouped("mailgun")
    mailgunGroup.post("template") { req async throws -> ClientResponse in
        let template = MailgunTemplate(name: "my-template", description: "api created :)", template: "<h1>Hello {{ name }}</h1>")
        return try await req.mailgunClient().createTemplate(template)
    }
}
```
