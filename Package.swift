// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Standup",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Standup", targets: ["Standup"]),
        .library(name: "StandupCore", targets: ["StandupCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "StandupCore",
            dependencies: [],
            path: "Sources/StandupCore"
        ),
        .executableTarget(
            name: "Standup",
            dependencies: ["StandupCore"],
            path: "Sources/Standup"
        ),
        .testTarget(
            name: "StandupTests",
            dependencies: ["StandupCore"],
            path: "Tests/StandupTests"
        )
    ]
)
