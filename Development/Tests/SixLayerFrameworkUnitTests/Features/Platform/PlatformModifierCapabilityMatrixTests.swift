//
//  PlatformModifierCapabilityMatrixTests.swift
//  SixLayerFrameworkTests
//
//  Secondary-platform View modifiers branch on a capability matrix (#448).
//  They do not clone iOS modifiers onto visionOS, tvOS, or watchOS.
//

import Testing
@testable import SixLayerFramework

@Suite("Platform modifier capability matrix")
struct PlatformModifierCapabilityMatrixTests {

    @Test
    func intrinsicIOSAppliesTouchHapticsPullToRefreshAndSwipe() {
        let matrix = PlatformModifierCapabilityMatrix.resolved(.intrinsic(for: .iOS))
        #expect(matrix.branch(for: .touch) == .apply)
        #expect(matrix.branch(for: .haptics) == .apply)
        #expect(matrix.branch(for: .pullToRefresh) == .apply)
        #expect(matrix.branch(for: .swipe) == .apply)
        #expect(matrix.branch(for: .hover) == .stubIdentity)
        #expect(matrix.branch(for: .pointer) == .stubIdentity)
        #expect(matrix.branch(for: .keyboard) == .stubIdentity)
        #expect(matrix.branch(for: .spatial) == .skipUnavailableAPI)
    }

    /// watchOS touch must not turn into an iOS pull-to-refresh clone.
    @Test
    func watchOSTouchDoesNotClonePullToRefresh() {
        let matrix = PlatformModifierCapabilityMatrix.resolved(.intrinsic(for: .watchOS))
        #expect(matrix.supports(.touch))
        #expect(matrix.branch(for: .pullToRefresh) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .swipe) == .apply)
        #expect(matrix.branch(for: .haptics) == .apply)
        #expect(matrix.branch(for: .hover) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .pointer) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .keyboard) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .spatial) == .skipUnavailableAPI)
    }

    @Test
    func tvOSKeyboardAppliesAndGestureAPIsSkip() {
        let matrix = PlatformModifierCapabilityMatrix.resolved(.intrinsic(for: .tvOS))
        #expect(matrix.branch(for: .keyboard) == .apply)
        #expect(matrix.branch(for: .swipe) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .pullToRefresh) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .hover) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .pointer) == .skipUnavailableAPI)
        #expect(matrix.branch(for: .haptics) == .stubIdentity)
        #expect(matrix.branch(for: .touch) == .stubIdentity)
        #expect(matrix.branch(for: .spatial) == .skipUnavailableAPI)
    }

    @Test
    func visionOSIsSpatialPointerNotTouchClone() {
        let matrix = PlatformModifierCapabilityMatrix.resolved(.intrinsic(for: .visionOS))
        #expect(matrix.branch(for: .spatial) == .apply)
        #expect(matrix.branch(for: .pointer) == .apply)
        #expect(matrix.branch(for: .hover) == .apply)
        #expect(matrix.branch(for: .touch) == .stubIdentity)
        #expect(matrix.branch(for: .haptics) == .stubIdentity)
        #expect(matrix.branch(for: .swipe) == .stubIdentity)
        #expect(matrix.branch(for: .pullToRefresh) == .stubIdentity)
        #expect(matrix.branch(for: .keyboard) == .stubIdentity)
    }

    @Test
    func macOSPointerAndKeyboardApplyWithoutTouch() {
        let matrix = PlatformModifierCapabilityMatrix.resolved(.intrinsic(for: .macOS))
        #expect(matrix.branch(for: .pointer) == .apply)
        #expect(matrix.branch(for: .hover) == .apply)
        #expect(matrix.branch(for: .keyboard) == .apply)
        #expect(matrix.branch(for: .touch) == .stubIdentity)
        #expect(matrix.branch(for: .haptics) == .stubIdentity)
        #expect(matrix.branch(for: .pullToRefresh) == .stubIdentity)
        #expect(matrix.branch(for: .swipe) == .stubIdentity)
        #expect(matrix.branch(for: .spatial) == .skipUnavailableAPI)
    }

    /// iPad pencil hover is `hover`, not a license to clone macOS pointer modifiers.
    @Test
    func iOSPencilHoverDoesNotEnablePointerModifiers() {
        var reading = PlatformModifierCapabilityReading.intrinsic(for: .iOS)
        reading.supportsHover = true
        let matrix = PlatformModifierCapabilityMatrix.resolved(reading)
        #expect(matrix.supports(.hover))
        #expect(matrix.branch(for: .hover) == .apply)
        #expect(matrix.branch(for: .pointer) == .stubIdentity)
    }

    @Test
    func disablingTouchOnIOSStubsPullToRefreshAndSwipe() {
        var reading = PlatformModifierCapabilityReading.intrinsic(for: .iOS)
        reading.supportsTouch = false
        let matrix = PlatformModifierCapabilityMatrix.resolved(reading)
        #expect(matrix.branch(for: .pullToRefresh) == .stubIdentity)
        #expect(matrix.branch(for: .swipe) == .stubIdentity)
        #expect(matrix.branch(for: .haptics) == .apply)
    }

    @Test
    func macOSTouchEnablesPullToRefreshAndSwipe() {
        var reading = PlatformModifierCapabilityReading.intrinsic(for: .macOS)
        reading.supportsTouch = true
        let matrix = PlatformModifierCapabilityMatrix.resolved(reading)
        #expect(matrix.branch(for: .pullToRefresh) == .apply)
        #expect(matrix.branch(for: .swipe) == .apply)
        #expect(matrix.branch(for: .pointer) == .apply)
    }

    @Test
    func hapticsBranchFollowsSupportsHapticFeedback() {
        var reading = PlatformModifierCapabilityReading.intrinsic(for: .iOS)
        reading.supportsHapticFeedback = false
        #expect(PlatformModifierCapabilityMatrix.resolved(reading).branch(for: .haptics) == .stubIdentity)

        var watch = PlatformModifierCapabilityReading.intrinsic(for: .watchOS)
        watch.supportsHapticFeedback = false
        #expect(PlatformModifierCapabilityMatrix.resolved(watch).branch(for: .haptics) == .stubIdentity)
    }

    /// Live host reading is passed through; this does not emulate another OS.
    @Test
    func currentMatrixMatchesLiveDetectionReading() {
        let platform = SixLayerPlatform.current
        let reading = PlatformModifierCapabilityReading(
            platform: platform,
            supportsTouch: RuntimeCapabilityDetection.supportsTouch,
            supportsHover: RuntimeCapabilityDetection.supportsHover,
            supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
            supportsKeyboardNavigation: platform.supportsKeyboardNavigation
        )
        #expect(PlatformModifierCapabilityMatrix.current == PlatformModifierCapabilityMatrix.resolved(reading))
    }
}
