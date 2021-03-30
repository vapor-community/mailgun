// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "mailgun",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Mailgun",
            targets: ["Mailgun"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor-community/mailgun-kit.git", .branch("v1")),
        .package(url: "https://github.com/vapor/email.git", .branch("api")),
    ],
    targets: [
        .target(
            name: "Mailgun",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Email", package: "email"),
                .product(name: "MailgunKit", package: "mailgun-kit"),
            ]
        ),
        .testTarget(
            name: "MailgunTests",
            dependencies: [
                .target(name: "Mailgun"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        ),
    ]
)
