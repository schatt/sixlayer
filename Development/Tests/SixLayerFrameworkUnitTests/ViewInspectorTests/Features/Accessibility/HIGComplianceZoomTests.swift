import Testing

//
//  HIGComplianceZoomTests.swift
//  SixLayerFrameworkTests
//
//  Validates automatic HIG compliance layout resilience under system zoom /
//  enlarged UI (Display Zoom), distinct from pinch-to-zoom (GitHub #303).
//

import SwiftUI
@testable import SixLayerFramework

@Suite("HIG Compliance - Zoom Support")
open class HIGComplianceZoomTests: BaseTestClass {

    @MainActor
    private func verifyViewIsHostable<V: View>(_ view: V, description: String) {
        _ = hostRootPlatformView(view)
        #expect(Bool(true), "\(description) should be hostable")
    }

    // MARK: - UI Scaling Tests

    @Test @MainActor func testViewScalesWithSystemZoom() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformSystemZoomPreference.withTestLayoutScale(1.2) {
                let view = platformVStackContainer {
                    Text("Zoom Test")
                        .automaticCompliance()
                    Button("Test Button") { }
                        .automaticCompliance()
                }
                .automaticCompliance()
                .dynamicTypeSize(.accessibility5)

                verifyViewIsHostable(
                    view,
                    description: "Automatic compliance under system zoom layout scale 1.2"
                )
                #expect(
                    PlatformSystemZoomPreference.layoutResilienceSpacing(
                        dynamicTypeSize: .accessibility5
                    ) > 0,
                    "Layout resilience spacing should apply at accessibility Dynamic Type with zoom scale"
                )
            }
        }
    }

    @Test @MainActor func testTextRemainsReadableAtZoomLevels() async {
        initializeTestConfig()
        #if os(iOS)
        let resolver = DynamicFontResolver()
        let bodySize = resolver.uiFont(for: .body, contentSize: .accessibilityExtraLarge).pointSize
        let minimum = PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: .iOS)
        #expect(bodySize >= minimum, "Body text at accessibility sizes should meet iOS minimum readable size")
        #elseif os(macOS)
        let resolver = DynamicFontResolver()
        let bodySize = resolver.nsFont(for: .body, contentSize: .accessibilityExtraLarge).pointSize
        let minimum = PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: .macOS)
        #expect(bodySize >= minimum, "Body text at accessibility sizes should meet macOS minimum readable size")
        #else
        #expect(
            PlatformSystemZoomPreference.minimumReadableBodyPointSize(
                for: RuntimeCapabilityDetection.currentPlatform
            ) > 0
        )
        #endif
    }

    @Test @MainActor func testButtonRemainsUsableAtZoomLevels() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformSystemZoomPreference.withTestLayoutScale(1.2) {
                let button = Button("Zoom Button") { }
                    .automaticCompliance()
                    .dynamicTypeSize(.accessibility3)

                verifyViewIsHostable(
                    button,
                    description: "Button with automatic compliance under layout scale 1.2"
                )

                let baseMin = RuntimeCapabilityDetection.minTouchTarget
                if baseMin > 0 {
                    let expectedMin = PlatformSystemZoomPreference.scaledTouchTargetMinimum(base: baseMin)
                    #expect(
                        expectedMin > baseMin,
                        "Touch-target floor should scale up when layout scale is 1.2"
                    )
                }
            }
        }
    }

    // MARK: - Layout Integrity Tests

    @Test @MainActor func testLayoutMaintainsIntegrityAtZoomLevels() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            PlatformSystemZoomPreference.withTestLayoutScale(1.2) {
                let view = platformVStackContainer {
                    platformHStackContainer {
                        Text("Left")
                            .automaticCompliance()
                        Text("Right")
                            .automaticCompliance()
                    }
                    .automaticCompliance()
                    Button("Action") { }
                        .automaticCompliance()
                }
                .automaticCompliance()
                .dynamicTypeSize(.accessibility5)

                verifyViewIsHostable(
                    view,
                    description: "Multi-control layout under zoom scale and accessibility Dynamic Type"
                )
                verifyViewContainsText(view, expectedText: "Left", testName: "layout-left-at-zoom")
                verifyViewContainsText(view, expectedText: "Right", testName: "layout-right-at-zoom")
                verifyViewContainsText(view, expectedText: "Action", testName: "layout-action-at-zoom")
            }
        }
    }

    // MARK: - Cross-Platform Tests

    @Test @MainActor func testZoomSupportOnAllPlatforms() async {
        initializeTestConfig()
        #expect(PlatformSystemZoomPreference.layoutScaleFactor >= 1.0)
        #expect(PlatformSystemZoomPreference.layoutScaleFactorFromSystem >= 1.0)
        let platform = RuntimeCapabilityDetection.currentPlatform
        #expect(
            PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: platform) > 0,
            "Each platform should define a minimum readable body size for zoom compliance"
        )
    }
}
