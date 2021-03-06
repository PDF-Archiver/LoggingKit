// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LoggingKit",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "LoggingKit",
            targets: ["LoggingKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/PDF-Archiver/LogModel.git", from: "0.0.4"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "LoggingKit",
            dependencies: ["LogModel", "Logging"]),
        .testTarget(
            name: "LoggingKitTests",
            dependencies: ["LoggingKit"]),
    ]
)
