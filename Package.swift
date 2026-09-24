// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftQiskit",
    platforms: [
        .macOS("27.0"),
        .iOS("27.0")
    ],
    products: [
        // Core library
        .library(
            name: "SwiftQiskit",
            targets: ["SwiftQiskit"]
        ),

        // CLI example
        .executable(
            name: "SwiftQiskitExamples",
            targets: ["SwiftQiskitExamples"]
        )
    ],
    targets: [
        // =========================
        // Core quantum engine
        // =========================
        .target(
            name: "SwiftQiskit",
            path: "Sources/SwiftQiskit"
        ),

        // =========================
        // CLI Example (Bell State)
        // =========================
        .executableTarget(
            name: "SwiftQiskitExamples",
            dependencies: ["SwiftQiskit"],
            path: "Examples"
        ),

        // =========================
        // Tests
        // =========================
        .testTarget(
            name: "SwiftQiskitTests",
            dependencies: ["SwiftQiskit"],
            path: "Tests/SwiftQiskitTests"
        )
    ]
)
