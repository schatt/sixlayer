// swift-tools-version: 6.0
// SixLayerFramework v8.3.5 - Patch: Field layout, presentation size, toolbar Menu, UITest MainActor (#352, #384–#387)
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
        ),
        // Optional ViewInspector helpers for consumer test targets (#327)
        .library(
            name: "SixLayerViewInspectorTestKit",
            targets: ["SixLayerViewInspectorTestKit"]
        )
    ],
    dependencies: [
        // Unreleased iOS 27 GeometryProxy-safe line (PR 421 / #408). Tagged 0.10.x SIGTRAPs.
        .package(url: "https://github.com/nalexn/ViewInspector", branch: "0.10.4"),
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

        // ViewInspector helpers for consumer test targets (#327). Test-only — not for app targets.
        .target(
            name: "SixLayerViewInspectorTestKit",
            dependencies: [
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "Framework/ViewInspectorTestKit/Sources",
            exclude: [
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

        /// Smoke tests for exported ViewInspector consumer helpers (#327).
        .testTarget(
            name: "SixLayerViewInspectorTestKitTests",
            dependencies: [
                "SixLayerViewInspectorTestKit",
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "Framework/ViewInspectorTestKit/Tests"
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
