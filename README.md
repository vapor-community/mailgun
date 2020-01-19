# Vapor Mailgun Service

[![Slack](https://img.shields.io/badge/join-slack-745EAF.svg?style=flat)](https://vapor.team)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2010.13%20|%20Ubuntu%2016.04%20LTS-ff0000.svg?style=flat)](http://cocoapods.org/pods/FASwift)
[![Swift 5.1](https://img.shields.io/badge/swift-5.1-orange.svg?style=flat)](http://swift.org)
[![Vapor 4](https://img.shields.io/badge/vapor-4.0-blue.svg?style=flat)](https://vapor.codes)

##

`Mailgun` is a Vapor 4 service for a popular [email sending API](https://www.mailgun.com/)
> Note: Vapor3 version is available in `vapor3` branch and from `3.0.0` tag


## Installation
Vapor Mailgun Service can be installed with Swift Package Manager

```swift
.package(url: "https://github.com/twof/VaporMailgunService.git", from: "4.0.0")

//and in targets add
//"Mailgun"
```

## Usage

### Sign up and set up a Mailgun account [here](https://www.mailgun.com/)
Make sure you get an API key and register a custom domain

### Configure

In `configure.swift`:

```swift
import Mailgun

// Called before your application initializes.
func configure(_ app: Application) throws {
    /// case 1
    /// put into your environment variables the following keys:
    /// MAILGUN_API_KEY=...
    app.mailgun.configuration = .environment

    /// case 2
    /// manually
    app.mailgun.configuration = .init(apiKey: "<api key>")
} 
```

> Note: If your private api key begins with `key-`, be sure to include it

### Declare all your domains

```swift
extension MailgunDomain {
    static var myApp1: MailgunDomain { .init("mg.myapp1.com", .us) }
    static var myApp2: MailgunDomain { .init("mg.myapp2.com", .eu) }
    static var myApp3: MailgunDomain { .init("mg.myapp3.com", .us) }
    static var myApp4: MailgunDomain { .init("mg.myapp4.com", .eu) }
}
```

Set default domain in `configure.swift`

```swift
app.mailgun.defaultDomain = .myApp1
```

### Usage

`Mailgun` is available on both `Application` and `Request`

```swift
// call it without arguments to use default domain
app.mailgun().send(...)
req.mailgun().send(...)

// or call it with domain
app.mailgun(.myApp1).send(...)
app.mailgun(.myApp1).send(...)
```

In `configure.swift`

```swift
import Mailgun

// Called before your application initializes.
func configure(_ app: Application) throws {
    /// configure mailgun
    
    /// then you're ready to use it
    app.mailgun(.myApp1).send(...).whenSuccess { response in
        print("just sent: \(response)")
    }
} 
```

All the examples below will be with  `Request`, but you could do the same with `Application` as in example above.

In `routes.swift`:

#### Without attachments

```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req -> EventLoopFuture<ClientResponse> in
        let message = MailgunMessage(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            text: "This is a newsletter",
            html: "<h1>This is a newsletter</h1>"
        )
        return req.mailgun().send(message)
    }
}
```

#### With attachments

```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req -> EventLoopFuture<ClientResponse> in
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
        return req.mailgun().send(message)
    }
}
```

#### With template (attachments can be used in same way)

```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req -> EventLoopFuture<ClientResponse> in
        let message = MailgunTemplateMessage(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            template: "my-template",
            templateData: ["foo": "bar"]
        )
        return req.mailgun().send(message)
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

With this, you can change the `#(name)` with a variable from your Swift code, when sending the mail

```swift
import Mailgun

func routes(_ app: Application) throws {
    app.post("mail") { req -> EventLoopFuture<ClientResponse> in
        let content = try req.view().render("Emails/my-email", [
            "name": "Bob"
        ])

        let message = Mailgun.Message(
            from: "postmaster@example.com",
            to: "example@gmail.com",
            subject: "Newsletter",
            text: "",
            html: content
        )
        
        return req.mailgun().send(message)
    }
}
```

#### Setup routes

```swift
public func configure(_ app: Application) throws {
    // sets up a catch_all forward for the route listed
    let routeSetup = MailgunRouteSetup(forwardURL: "http://example.com/mailgun/all", description: "A route for all emails")
    app.mailgun().setup(forwarding: routeSetup).whenSuccess { response in
        print(response)
    }
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
    mailgunGroup.post("template") { req -> EventLoopFuture<ClientResponse> in
        let template = MailgunTemplate(name: "my-template", description: "api created :)", template: "<h1>Hello {{ name }}</h1>")
        return req.mailgun().createTemplate(template)
    }
}
```
