// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ekko-app",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "EkkoCore", targets: ["EkkoCore"]),
        .library(name: "EkkoPlatform", targets: ["EkkoPlatform"]),
        .executable(name: "EkkoCLI", targets: ["EkkoCLI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.3.0"
        ),
    ],
    targets: [
        .target(
            name: "EkkoCore",
            dependencies: []
        ),
        .target(
            name: "EkkoPlatform",
            dependencies: ["EkkoCore"]
        ),
        .executableTarget(
            name: "EkkoCLI",
            dependencies: [
                "EkkoPlatform",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "EkkoCoreTests",
            dependencies: ["EkkoCore"]
        ),
        .testTarget(
            name: "EkkaPlatformTests",
            dependencies: ["EkkoPlatform"]
        ),
    ]
)
