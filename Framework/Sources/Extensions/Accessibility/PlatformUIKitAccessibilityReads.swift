import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// MainActor-safe reads of UIKit `UIAccessibility` statics for nonisolated callers (GitHub #305).
///
/// When not on the main thread, returns conservative defaults so callers do not crash.
#if os(iOS) || os(visionOS) || os(tvOS)
enum PlatformUIKitAccessibilityReads {
    static var isVoiceOverRunning: Bool {
        mainActorProbe { UIAccessibility.isVoiceOverRunning } ?? false
    }

    static var isDarkerSystemColorsEnabled: Bool {
        mainActorProbe { UIAccessibility.isDarkerSystemColorsEnabled } ?? false
    }

    static var isReduceTransparencyEnabled: Bool {
        mainActorProbe { UIAccessibility.isReduceTransparencyEnabled } ?? false
    }

    static var isSwitchControlRunning: Bool {
        mainActorProbe { UIAccessibility.isSwitchControlRunning } ?? false
    }

    static var isReduceMotionEnabled: Bool {
        mainActorProbe { UIAccessibility.isReduceMotionEnabled } ?? false
    }

    private static func mainActorProbe<T: Sendable>(_ probe: @MainActor () -> T) -> T? {
        guard Thread.isMainThread else { return nil }
        return MainActor.assumeIsolated { probe() }
    }
}
#endif
