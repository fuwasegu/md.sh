// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MdSh",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MdSh", targets: ["MdSh"]),
        .library(name: "MdShCore", targets: ["MdShCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown", from: "0.4.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", branch: "main"),
    ],
    targets: [
        // Main executable - just the entry point
        .executableTarget(
            name: "MdSh",
            dependencies: ["MdShCore"]
        ),
        // Core library - all the app logic
        .target(
            name: "MdShCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        // Tests
        .testTarget(
            name: "MdShTests",
            dependencies: ["MdShCore"]
        ),
    ]
)
