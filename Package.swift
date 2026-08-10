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
        .library(name: "SmartQueueMusicKit", targets: ["SmartQueueMusicKit"])
    ],
    targets: [
        .target(
            name: "SmartQueueCore"
        ),
        .target(
            name: "SmartQueueMusicKit",
            dependencies: ["SmartQueueCore"],
            linkerSettings: [
                .linkedFramework("MusicKit")
            ]
        ),
        .testTarget(
            name: "SmartQueueCoreTests",
            dependencies: ["SmartQueueCore"]
        )
    ]
)
