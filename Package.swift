// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = [
    .library(name: "SmartQueueCore", targets: ["SmartQueueCore"])
]

var targets: [Target] = [
    .target(
        name: "SmartQueueCore"
    ),
    .testTarget(
        name: "SmartQueueCoreTests",
        dependencies: ["SmartQueueCore"]
    )
]

#if !os(Linux)
products.append(
    .library(name: "SmartQueueMusicKit", targets: ["SmartQueueMusicKit"])
)

targets.append(
    .target(
        name: "SmartQueueMusicKit",
        dependencies: ["SmartQueueCore"],
        linkerSettings: [
            .linkedFramework("MusicKit")
        ]
    )
)
#endif

let package = Package(
    name: "AppleMusicSmartQueue",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v18)
    ],
    products: products,
    targets: targets
)
