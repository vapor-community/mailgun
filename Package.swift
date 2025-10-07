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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.117.0"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "0.1.1"),
    ],
    targets: [
        .target(
            name: "Mailgun",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),
        .testTarget(
            name: "MailgunTests",
            dependencies: [
                .target(name: "Mailgun"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),
    ]
)
