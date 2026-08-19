// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppleMusicSmartQueue",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "SmartQueueCore", targets: ["SmartQueueCore"]),
        .library(name: "SmartQueueMusicKit", targets: ["SmartQueueMusicKit"]),
        .library(name: "SmartQueueAppSupport", targets: ["SmartQueueApp"])
    ],
    targets: [
        .target(
            name: "SmartQueueCore"
        ),
        .target(
            name: "SmartQueueDomain",
            dependencies: ["SmartQueueCore"]
        ),
        .target(
            name: "SmartQueueStorage",
            dependencies: ["SmartQueueCore", "SmartQueueDomain"]
        ),
        .target(
            name: "SmartQueueObservation",
            dependencies: ["SmartQueueCore", "SmartQueueDomain"]
        ),
        .target(
            name: "SmartQueueIntelligence",
            dependencies: ["SmartQueueCore", "SmartQueueDomain", "SmartQueueStorage"]
        ),
        .target(
            name: "SmartQueueQueue",
            dependencies: ["SmartQueueCore", "SmartQueueDomain"]
        ),
        .target(
            name: "SmartQueueMusicKit",
            dependencies: ["SmartQueueCore", "SmartQueueDomain", "SmartQueueObservation", "SmartQueueQueue"],
            linkerSettings: [
                .linkedFramework("MusicKit")
            ]
        ),
        .target(
            name: "SmartQueueApp",
            dependencies: [
                "SmartQueueCore",
                "SmartQueueDomain",
                "SmartQueueStorage",
                "SmartQueueObservation",
                "SmartQueueIntelligence",
                "SmartQueueQueue",
                "SmartQueueMusicKit"
            ]
        ),
        .testTarget(
            name: "SmartQueueCoreTests",
            dependencies: ["SmartQueueCore"]
        ),
        .testTarget(
            name: "SmartQueueDomainTests",
            dependencies: ["SmartQueueDomain"]
        ),
        .testTarget(
            name: "SmartQueueStorageTests",
            dependencies: ["SmartQueueStorage"]
        ),
        .testTarget(
            name: "SmartQueueObservationTests",
            dependencies: ["SmartQueueObservation"]
        ),
        .testTarget(
            name: "SmartQueueIntelligenceTests",
            dependencies: ["SmartQueueIntelligence"]
        ),
        .testTarget(
            name: "SmartQueueQueueTests",
            dependencies: ["SmartQueueQueue"]
        )
    ]
)
