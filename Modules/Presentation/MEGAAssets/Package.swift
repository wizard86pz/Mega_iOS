// swift-tools-version: 5.10

import PackageDescription

let settings: [SwiftSetting] = [.unsafeFlags(["-warnings-as-errors"]),
                                .enableExperimentalFeature("ExistentialAny"),
                                .enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "MEGAAssets",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "MEGAAssets",
            targets: ["MEGAAssets"])
    ],
    dependencies: [
        .package(path: "../../../Infrastructure/MEGASwift")
    ],
    targets: [
        .target(
            name: "MEGAAssets",
            dependencies: [
                "MEGASwift"
            ],
            swiftSettings: settings),
        .testTarget(
            name: "MEGAAssetsTests",
            dependencies: ["MEGAAssets"],
            swiftSettings: settings)
    ]
)
