// swift-tools-version:6.2
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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.120.0"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.2", traits: []),
    ],
    targets: [
        .target(
            name: "Mailgun",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MailgunTests",
            dependencies: [
                .target(name: "Mailgun"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        //.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
    ]
}
