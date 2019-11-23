# Vapor Mailgun Service

[![Slack](https://img.shields.io/badge/join-slack-745EAF.svg?style=flat)](https://vapor.team)
[![Platforms](https://img.shields.io/badge/platforms-macOS%2010.13%20|%20Ubuntu%2016.04%20LTS-ff0000.svg?style=flat)](http://cocoapods.org/pods/FASwift)
[![Swift 4.1](https://img.shields.io/badge/swift-4.1-orange.svg?style=flat)](http://swift.org)
[![Vapor 3](https://img.shields.io/badge/vapor-3.0-blue.svg?style=flat)](https://vapor.codes)

##

`Mailgun` is a Vapor 3 service for a popular [email sending API](https://www.mailgun.com/)


## Installation
Vapor Mailgun Service can be installed with Swift Package Manager

```swift
.package(url: "https://github.com/twof/VaporMailgunService.git", from: "1.5.0")
```

## Usage

### Sign up and set up a Mailgun account [here](https://www.mailgun.com/)
Make sure you get an API key and register a custom domain

### Configure

In `configure.swift`:

#### Single Domain Configuration

```swift
let mailgun = Mailgun(apiKey: "<api key>", domain: "mg.example.com", region: .eu)
services.register(mailgun, as: Mailgun.self)
```

> Note: If your private api key begins with `key-`, be sure to include it

#### Multiple Domain Configuration

```swift
let domain1 = Mailgun.DomainConfig("mg.example.com", region: .eu)
let domain2 = Mailgun.DomainConfig("mg.example2.com", region: .us)
let mailgun = try Mailgun(apiKey: "<api key>", domains: [domain1, domain2])
services.register(mailgun, as: Mailgun.self)
```

> Note: If you omit the domain parameter (eg in send, createTemplate, ..) it will take the first out of the array - in this case domain1 (mg.example.com)


### Use

In `routes.swift`:

#### Without attachments

```swift
router.post("mail") { (req) -> Future<Response> in
    let message = Mailgun.Message(
        from: "postmaster@example.com",
        to: "example@gmail.com",
        subject: "Newsletter",
        text: "This is a newsletter",
        html: "<h1>This is a newsletter</h1>"
    )

    let mailgun = try req.make(Mailgun.self)
    return try mailgun.send(message, on: req) 
    // for selecting a specific domain use 
    // mailgun.send(message, domain: "mg2.example.com", on: req)
    // same for the other functions
}
```

#### With attachments

```swift
router.post("mail") { (req) -> Future<Response> in
    let fm = FileManager.default
    guard let attachmentData = fm.contents(atPath: "/tmp/test.pdf") else {
        throw Abort(.internalServerError)
    }
    let attachment = File(data: attachmentData, filename: "test.pdf")
    let message = Mailgun.Message(
        from: "postmaster@example.com",
        to: "example@gmail.com",
        subject: "Newsletter",
        text: "This is a newsletter",
        html: "<h1>This is a newsletter</h1>",
        attachments: [attachment]
    )

    let mailgun = try req.make(Mailgun.self)
    return try mailgun.send(message, on: req)
}
```

#### With template (attachments can be used in same way)

```swift
router.post("mail") { (req) -> Future<Response> in
    let message = Mailgun.TemplateMessage(
        from: "postmaster@example.com",
        to: "example@gmail.com",
        subject: "Newsletter",
        template: "my-template",
        templateData: ["foo": "bar"]
    )

    let mailgun = try req.make(Mailgun.self)
    return try mailgun.send(message, on: req)
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
router.post("mail") { (req) -> Future<Response> in
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

    let mailgun = try req.make(Mailgun.self)
    return try mailgun.send(message, on: req)
}
```

#### Setup routes

```swift
public func boot(_ app: Application) throws {
    // sets up a catch_all forward for the route listed
    let routeSetup = RouteSetup(forwardURL: "http://example.com/mailgun/all", description: "A route for all emails")
    let mailgunClient = try app.make(Mailgun.self)
    try mailgunClient.setup(forwarding: routeSetup, with: app).map { (resp) in
        print(resp)
    }
}
```

#### Handle routes

```swift
mailgunGroup.post("all") { (req) -> Future<String> in
    do {
        return try req.content.decode(IncomingMailgun.self).map { (incomingMail) in
            return "Hello"
        }
    } catch {
        throw Abort(HTTPStatus.internalServerError, reason: "Could not decode incoming message")
    }
}
```

#### Creating templates

```swift
router.post("template") { (req) -> Future<Response> in
    let template = Mailgun.Template(name: "my-template", description: "api created :)", template: "<h1>Hello {{ name }}</h1>")
    
    let mailgun = try req.make(Mailgun.self)
    return try mailgun.createTemplate(template, on: req)
}
```
