// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppleMusicSmartQueue",
    defaultLocalization: "zh-Hans",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SmartQueueCore", targets: ["SmartQueueCore"]),
        .library(name: "SmartQueueDomain", targets: ["SmartQueueDomain"]),
        .library(name: "SmartQueueMusicKit", targets: ["SmartQueueMusicKit"]),
        .library(name: "SmartQueueIntelligence", targets: ["SmartQueueIntelligence"])
    ],
    targets: [
        .target(name: "SmartQueueCore"),
        .target(name: "SmartQueueDomain", dependencies: ["SmartQueueCore"]),
        .target(name: "SmartQueueIntelligence", dependencies: ["SmartQueueCore", "SmartQueueDomain"]),
        .target(
            name: "SmartQueueMusicKit",
            dependencies: ["SmartQueueCore", "SmartQueueDomain", "SmartQueueIntelligence"],
            linkerSettings: [.linkedFramework("MusicKit")]
        ),
        .testTarget(name: "SmartQueueCoreTests", dependencies: ["SmartQueueCore"]),
        .testTarget(name: "SmartQueueDomainTests", dependencies: ["SmartQueueDomain"]),
        .testTarget(name: "SmartQueueIntelligenceTests", dependencies: ["SmartQueueIntelligence"])
    ]
)
