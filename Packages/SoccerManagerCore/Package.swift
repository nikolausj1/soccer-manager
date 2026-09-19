// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SoccerManagerCore",
    platforms: [
        .iOS("26.0"),
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "SoccerManagerCore",
            targets: ["SoccerManagerCore"]
        )
    ],
    targets: [
        .target(
            name: "SoccerManagerCore"
        ),
        .testTarget(
            name: "SoccerManagerCoreTests",
            dependencies: ["SoccerManagerCore"]
        )
    ]
)
