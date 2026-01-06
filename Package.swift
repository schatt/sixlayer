// swift-tools-version: 6.0
// SixLayerFramework v6.8.0 - DRY Improvements - Platform Switch Consolidation
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SixLayerFramework",
    platforms: [
        .iOS(.v17),
        .macOS(.v15)
    ],
    products: [
        // Main framework product - single library for all platforms
        .library(
            name: "SixLayerFramework",
            targets: ["SixLayerFramework"]
        ),
        // Test kit for consumers of the framework
        .library(
            name: "SixLayerTestKit",
            targets: ["SixLayerTestKit"]
        )
    ],
    targets: [
        // Main framework target - organized into logical structure
        .target(
            name: "SixLayerFramework",
            dependencies: [],
            path: "Framework/Sources",
            exclude: [
                "Core/ExampleHelpers.swift",
                "Core/ExtensibleHintsExample.swift"
            ],
            sources: [
                "Core",
                "Layers",
                "Components",
                "Platform",
                "Extensions",
                "Services"
            ],
            resources: [
                .process("../Resources")
            ],
            swiftSettings: [
                // Enable previews only when building in Xcode (where PreviewsMacros plugin is available)
                // Command-line builds (swift test, swift build) don't have PreviewsMacros plugin
                // Uncomment this line when building in Xcode to enable #Preview macros:
                // .define("ENABLE_PREVIEWS")
            ]
        ),

        // SixLayerTestKit - Testing utilities for consumers of the framework
        .target(
            name: "SixLayerTestKit",
            dependencies: [
                "SixLayerFramework"
            ],
            path: "Framework/TestKit/Sources",
            exclude: [
                // Documentation files
                "README.md"
            ]
        ),

        // Unit tests - main test suite
        .testTarget(
            name: "SixLayerFrameworkUnitTests",
            dependencies: [
                "SixLayerFramework",
                "SixLayerTestKit"
            ],
            path: "Development/Tests/SixLayerFrameworkUnitTests",
            exclude: [
                // Documentation and example files
                "BugReports/PlatformTypes_v4.6.4/README.md",
                "BugReports/README.md",
                "BugReports/PlatformTypes_v4.6.6/README.md",
                "BugReports/ButtonStyle_v4.6.3/README.md",
                "BugReports/PlatformImage_v4.6.2/README.md",
                "BugReports/PlatformPhotoPicker_v4.6.5/README.md",
                "ViewInspectorTests/Utilities/TestHelpers/CoreDataTestingGuide.md",
                "Utilities/TestHelpers/CoreDataTestingGuide.md"
            ],
            swiftSettings: [
                // Disable strict concurrency checking for tests to work around Swift 6 region-based isolation checker issues
                .define("SWIFT_DISABLE_STRICT_CONCURRENCY_CHECKING")
            ]
        ),

    ]
)
