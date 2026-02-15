// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MonitorSwitch",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "MonitorSwitch",
            path: "Sources/MonitorSwitch",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ]
)
