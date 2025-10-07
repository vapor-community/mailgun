// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "mailgun",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "Mailgun", targets: ["Mailgun"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.117.0")
    ],
    targets: [
        .target(
            name: "Mailgun",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "MailgunTests",
            dependencies: [
                .target(name: "Mailgun"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)
