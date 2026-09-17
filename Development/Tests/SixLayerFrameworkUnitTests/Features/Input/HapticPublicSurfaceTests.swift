//
//  HapticPublicSurfaceTests.swift
//  SixLayerFrameworkTests
//
//  App-facing haptic contract (#445): one style enum mapping, one capability
//  gate. Does not assert Taptic Engine firing.
//

import Testing
import SwiftUI
@testable import SixLayerFramework

@Suite("Haptic public surface")
struct HapticPublicSurfaceTests {

    /// iOS L5 styles are a subset of `PlatformHapticFeedback` and must map 1:1.
    /// macOS lane: `IOSHapticStyle` is not compiled.
    @Test
    func iosHapticStyleMapsOneToOneOntoPlatformHapticFeedback() {
        #if os(iOS)
        #expect(IOSHapticStyle.light.platformHapticFeedback == .light)
        #expect(IOSHapticStyle.medium.platformHapticFeedback == .medium)
        #expect(IOSHapticStyle.heavy.platformHapticFeedback == .heavy)
        #expect(IOSHapticStyle.success.platformHapticFeedback == .success)
        #expect(IOSHapticStyle.warning.platformHapticFeedback == .warning)
        #expect(IOSHapticStyle.error.platformHapticFeedback == .error)
        #endif
    }

    /// Shared trigger fires the requested style only when haptics are supported.
    @Test
    func resolvedFeedbackPassesThroughWhenSupported() {
        #expect(SixLayerHaptic.resolvedFeedback(.success, supported: true) == .success)
        #expect(SixLayerHaptic.resolvedFeedback(.light, supported: true) == .light)
        #expect(SixLayerHaptic.resolvedFeedback(.rigid, supported: true) == .rigid)
    }

    @Test
    func resolvedFeedbackIsNilWhenUnsupported() {
        for style in PlatformHapticFeedback.allCases {
            #expect(
                SixLayerHaptic.resolvedFeedback(style, supported: false) == nil,
                "unsupported haptics must not resolve \(style)"
            )
        }
    }
}
