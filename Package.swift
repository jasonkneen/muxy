// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Muxy",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        // C module exposing the ghostty.h header
        .target(
            name: "GhosttyKit",
            path: "GhosttyKit",
            publicHeadersPath: "."
        ),
        // The main app, links against the prebuilt static library
        .executableTarget(
            name: "Muxy",
            dependencies: ["GhosttyKit"],
            path: "Muxy",
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-L", "GhosttyKit.xcframework/macos-arm64_x86_64",
                    "-lghostty",
                ]),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreText"),
                .linkedFramework("Foundation"),
                .linkedFramework("IOKit"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("QuartzCore"),
                .linkedLibrary("c++"),
            ]
        ),
    ]
)
