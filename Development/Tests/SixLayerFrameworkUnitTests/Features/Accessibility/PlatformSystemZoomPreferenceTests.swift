import SwiftUI
import Testing
@testable import SixLayerFramework

/// Unit coverage for system zoom / layout-scale policy (GitHub #303).
@Suite("Platform System Zoom Preference")
open class PlatformSystemZoomPreferenceTests: BaseTestClass {

    @Test @MainActor func testLayoutScaleFactorHonorsTaskLocalOverride() {
        initializeTestConfig()
        PlatformSystemZoomPreference.withTestLayoutScale(1.25) {
            #expect(PlatformSystemZoomPreference.layoutScaleFactor == 1.25)
        }
        #expect(PlatformSystemZoomPreference.layoutScaleFactor == 1.0)
    }

    @Test @MainActor func testLayoutScaleFactorClampsBelowOneToOne() {
        initializeTestConfig()
        PlatformSystemZoomPreference.withTestLayoutScale(0.5) {
            #expect(PlatformSystemZoomPreference.layoutScaleFactor == 1.0)
        }
    }

    @Test @MainActor func testScaledTouchTargetMinimumMultipliesBaseByLayoutScale() {
        initializeTestConfig()
        PlatformSystemZoomPreference.withTestLayoutScale(1.2) {
            let scaled = PlatformSystemZoomPreference.scaledTouchTargetMinimum(base: 44.0)
            #expect(abs(scaled - 52.8) < 0.01, "Touch target should scale 44pt by layout scale 1.2")
        }
    }

    @Test @MainActor func testLayoutResilienceSpacingPositiveWhenZoomOverrideActive() {
        initializeTestConfig()
        PlatformSystemZoomPreference.withTestLayoutScale(1.2) {
            let spacing = PlatformSystemZoomPreference.layoutResilienceSpacing(
                dynamicTypeSize: .large
            )
            #expect(spacing > 0, "Layout resilience spacing should apply when layout scale > 1")
        }
    }

    @Test @MainActor func testLayoutResilienceSpacingPositiveAtAccessibilityDynamicType() {
        initializeTestConfig()
        let spacing = PlatformSystemZoomPreference.layoutResilienceSpacing(
            dynamicTypeSize: .accessibility3
        )
        #expect(spacing > 0, "Layout resilience spacing should apply at accessibility Dynamic Type sizes")
    }

    @Test @MainActor func testMinimumReadableBodyPointSizeMatchesPlatformHIGFloors() {
        initializeTestConfig()
        #expect(PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: .iOS) == 17.0)
        #expect(PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: .macOS) == 13.0)
        #expect(PlatformSystemZoomPreference.minimumReadableBodyPointSize(for: .tvOS) == 24.0)
    }
}
