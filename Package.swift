// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MdSh",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MdSh", targets: ["MdSh"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown", from: "0.4.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "MdSh",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
