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
.package(url: "https://github.com/twof/VaporMailgunService.git", from: "1.1.0")
```

## Usage

### Sign up and set up a Mailgun account [here](https://www.mailgun.com/)
Make sure you get an API key and register a custom domain

### Configure

In `configure.swift`:

```swift
let mailgun = Mailgun(apiKey: "<api key>", domain: "mg.example.com")
services.register(mailgun, as: Mailgun.self)
```

Note: If your private api key begins with `key-`, be sure to include it

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

#### Setup routes

```swift
public func boot(_ app: Application) throws {
    // sets up a catch_all forward for the route listed
    let routeSetup = RouteSetup(forwardURL: "http://example.com/mailgun/all", description: "A route for all emails")
    let mailgunClient = try app.make(Mailgun.self)
    try mailgunClient.setupForwarding(setup: routeSetup, with: app).map { (resp) in
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
        throw Abort(HTTPStatus.internalServerError, reason: "Could not decode incoming Mailgun")
    }
}
```
