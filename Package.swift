// swift-tools-version: 6.0
// SixLayerFramework v7.8.6 - Patch: OCR overlay bounding boxes (#291)
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
            path: "Framework",
            exclude: [
                "Sources/Core/ExampleHelpers.swift",
                "Sources/Core/ExtensibleHintsExample.swift"
            ],
            sources: [
                "Sources"
            ],
            resources: [
                .copy("Resources/Localizable.xcstrings")
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

        // Full unit test suite is built and run via Xcode (see project.yml); SwiftPM does not include
        // SixLayerFrameworkUnitTests because it depends on shared test helpers and ViewInspector wiring
        // that are not fully represented here.

        /// Isolated unit tests for pure layout resolver logic (no ViewInspector / BaseTestClass).
        /// Enables `swift test` / `swift test --filter NavigationLayoutResolverTests` without building the full UI test suite.
        .testTarget(
            name: "NavigationLayoutResolverTests",
            dependencies: [
                "SixLayerFramework"
            ],
            path: "Development/Tests/NavigationLayoutResolverTests"
        ),

        /// Pure routing policy for managed settings flow (#209); no ViewInspector / BaseTestClass.
        .testTarget(
            name: "PlatformManagedSettingsFlowLogicTests",
            dependencies: [
                "SixLayerFramework"
            ],
            path: "Development/Tests/SixLayerFrameworkUnitTests/Features/Navigation",
            sources: [
                "PlatformManagedSettingsFlowLogicTests.swift",
                "PlatformManagedSettingsTopLevelStateTests.swift",
                "PlatformManagedSettingsFlowLayer4Tests.swift",
                "PlatformManagedSettingsDetailNavigationStateTests.swift",
                "PlatformManagedSettingsDetailNavigationLayer4Tests.swift",
                "ManagedPlatformSettingsFlowGuideExampleTests.swift"
            ]
        ),

        /// Public UI test navigation contract types in SixLayerTestKit (#227).
        .testTarget(
            name: "SixLayerUITestNavigationContractTests",
            dependencies: [
                "SixLayerTestKit"
            ],
            path: "Development/Tests/SixLayerUITestNavigationContractTests"
        ),

        /// Pure OCR overlay geometry helpers (#291).
        .testTarget(
            name: "OCRBoundingBoxLayoutTests",
            dependencies: [
                "SixLayerFramework"
            ],
            path: "Development/Tests/OCRBoundingBoxLayoutTests"
        ),

    ]
)
