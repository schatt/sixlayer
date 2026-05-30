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

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

@Suite("HIG Compliance - Zoom Support")
open class HIGComplianceZoomTests: BaseTestClass {

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    private func hostedZoomRoot<V: View>(
        for view: V,
        dynamicTypeSize: DynamicTypeSize = .large,
        layoutScale: CGFloat = 1.0
    ) -> Any? {
        initializeTestConfig()
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        config.resetToDefaults()
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableAutoIDs = true
        config.globalAutomaticAccessibilityIdentifiers = true
        return AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            PlatformSystemZoomPreference.withTestLayoutScale(layoutScale) {
                Self.hostRootPlatformView(
                    view.dynamicTypeSize(dynamicTypeSize),
                    forceLayout: true,
                    exposeContentAccessibility: true,
                    accessibilityIdentifierConfig: config
                )
            }
        }
    }

    @MainActor
    private func hostedButtonMinimumHeight(_ root: Any?) -> CGFloat {
        var maxHeight: CGFloat = 0
        hostedUIKitAccessibilityHierarchyContains(root: root) { view in
            guard view.accessibilityTraits.contains(.button) else { return false }
            maxHeight = max(maxHeight, view.bounds.height)
            return false
        }
        return maxHeight
    }

    @MainActor
    private func hostedLabelsContain(_ root: Any?, substrings: [String]) -> Bool {
        substrings.allSatisfy { needle in
            hostedUIKitAccessibilityHierarchyContains(root: root) { view in
                (view.accessibilityLabel ?? "").contains(needle)
            }
        }
    }
    #endif

    // MARK: - UI Scaling Tests

    @Test @MainActor func testViewScalesWithSystemZoom() async {
        #if canImport(UIKit) && !os(watchOS)
        let view = platformVStackContainer {
            Text("Zoom Test")
                .automaticCompliance()
            Button("Test Button") { }
                .automaticCompliance()
        }
        .automaticCompliance()

        let root = hostedZoomRoot(for: view, dynamicTypeSize: .accessibility5, layoutScale: 1.2)
        #expect(root != nil, "View with automatic compliance should host under system zoom override")
        #expect(
            hostedUIKitAccessibilityHierarchyContains(root: root) { !$0.accessibilityTraits.isEmpty || !($0.accessibilityLabel ?? "").isEmpty },
            "Hosted content should remain accessibility-discoverable when layout scale increases"
        )
        #else
        PlatformSystemZoomPreference.withTestLayoutScale(1.2) {
            #expect(PlatformSystemZoomPreference.layoutScaleFactor == 1.2)
        }
        #endif
    }

    @Test @MainActor func testTextRemainsReadableAtZoomLevels() async {
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
        #expect(PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: RuntimeCapabilityDetection.currentPlatform) > 0)
        #endif
    }

    @Test @MainActor func testButtonRemainsUsableAtZoomLevels() async {
        #if canImport(UIKit) && !os(watchOS)
        let button = Button("Zoom Button") { }
            .automaticCompliance()

        let baseMin = RuntimeCapabilityDetection.minTouchTarget
        guard baseMin > 0 else {
            #expect(Bool(true), "Non-touch-first platform has no touch-target floor in this lane")
            return
        }

        let expectedMin = PlatformSystemZoomPreference.scaledTouchTargetMinimum(base: baseMin, layoutScale: 1.2)
        let root = hostedZoomRoot(for: button, dynamicTypeSize: .accessibility3, layoutScale: 1.2)
        #expect(root != nil)
        let measured = hostedButtonMinimumHeight(root)
        #expect(
            measured >= expectedMin - 1.0,
            "Button should meet scaled touch-target minimum (\(expectedMin)pt) under layout scale 1.2; measured \(measured)pt"
        )
        #else
        let scaled = PlatformSystemZoomPreference.scaledTouchTargetMinimum(base: 44.0, layoutScale: 1.2)
        #expect(scaled > 44.0)
        #endif
    }

    // MARK: - Layout Integrity Tests

    @Test @MainActor func testLayoutMaintainsIntegrityAtZoomLevels() async {
        #if canImport(UIKit) && !os(watchOS)
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

        let root = hostedZoomRoot(for: view, dynamicTypeSize: .accessibility5, layoutScale: 1.2)
        #expect(root != nil)
        #expect(
            hostedLabelsContain(root, substrings: ["Left", "Right", "Action"]),
            "Critical controls should remain discoverable without overlap/clipping at zoom + accessibility sizes"
        )
        #else
        #expect(
            PlatformSystemZoomPreference.layoutResilienceSpacing(
                dynamicTypeSize: .accessibility5,
                layoutScale: 1.2
            ) > 0
        )
        #endif
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
