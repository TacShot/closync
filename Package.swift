// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Closync",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Closync", targets: ["Closync"])
    ],
    targets: [
        .executableTarget(
            name: "Closync",
            path: "Sources/Closync"
        )
    ]
)
