# Vapor Mailgun Service

`MailgunEngine` is a service to be used with Vapor to send emails.

## Installation
Vapor Mailgun Service can be installed with Swift Package Manager

```swift
.package(url: "https://github.com/twof/VaporMailgunService.git", from: "0.0.1")
```

## Usage

### [Sign up and set up a Mailgun account](https://www.mailgun.com/)
Make sure you get an API key and register a custom domain

### Configure MailgunEngine
In `configure.swift`:

```swift
let mailgunEngine = MailgunEngine(apiKey: "<api key>", customURL: "mg.example.com")
services.register(mailgunEngine, as: Mailgun.self)
```

### Make and use MailgunEngine
In `routes.swift`:

```swift
router.post("mail") { (req) -> Future<Response> in
    let content: MailgunFormData = MailgunFormData(
        from: "postmaster@example.com",
        to: "example@gmail.com",
        subject: "Newsletter",
        text: "This is a newsletter"
    )
    
    let mailgunClient = try req.make(Mailgun.self)
    return try mailgunClient.sendMail(data: content, on: req)
}
```
