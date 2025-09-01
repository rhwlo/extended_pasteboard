// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "extended_pasteboard",
    platforms: [.macOS("13.0")],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-subprocess", branch: "main"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4"),
    ],
    targets: [
        .executableTarget(
            name: "extended_pasteboard",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ])
    ]
)
