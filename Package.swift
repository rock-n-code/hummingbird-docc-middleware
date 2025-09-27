// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: DocCMiddleware.package,
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: DocCMiddleware.package,
            targets: [DocCMiddleware.target]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: DocCMiddleware.target,
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Sources/DocCMiddleware",
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency=complete")]
        ),
        .testTarget(
            name: DocCMiddleware.test,
            dependencies: [
                .product(name: "HummingbirdTesting", package: "hummingbird"),
                .byName(name: DocCMiddleware.target)
            ],
            path: "Tests/DocCMiddleware"
        ),
    ]
)

// MARK: - Constants

enum DocCMiddleware {
    static let package = "hummingbird-docc"
    static let target = "DocCMiddleware"
    static let test = "\(DocCMiddleware.target)Tests"
}
