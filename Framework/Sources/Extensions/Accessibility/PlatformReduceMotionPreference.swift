import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

/// Framework-owned reduce-motion policy for animation APIs (GitHub #298).
///
/// SwiftUI views should prefer `@Environment(\.accessibilityReduceMotion)` in modifiers;
/// non-view code uses `isReduceMotionEnabled`, which honors `@TaskLocal` test overrides.
public enum PlatformReduceMotionPreference: Sendable {

    /// When non-`nil`, overrides system reduce-motion reads for the current task (unit tests).
    @TaskLocal public static var testOverride: Bool?

    /// Whether decorative animation should be suppressed for the current execution context.
    public static var isReduceMotionEnabled: Bool {
        if let testOverride {
            return testOverride
        }
        return isReduceMotionEnabledFromSystem
    }

    /// Reads reduce motion from platform accessibility APIs (no SwiftUI environment).
    public static var isReduceMotionEnabledFromSystem: Bool {
        #if os(iOS) || os(visionOS) || os(tvOS)
        return UIAccessibility.isReduceMotionEnabled
        #elseif os(watchOS)
        // UIAccessibility.isReduceMotionEnabled is unavailable on watchOS; SwiftUI views use
        // @Environment(\.accessibilityReduceMotion) via PlatformReduceMotionSubtreeModifier.
        return false
        #elseif os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
        return false
        #endif
    }

    /// Returns `nil` when reduce motion is enabled so callers apply `.animation(.none, …)`.
    public static func resolvedAnimation(
        _ animation: Animation,
        reduceMotionEnabled: Bool
    ) -> Animation? {
        reduceMotionEnabled ? nil : animation
    }

    /// Run `body` with a task-local reduce-motion override (parallel-test safe).
    public static func withTestOverride<T>(
        _ enabled: Bool,
        _ body: () throws -> T
    ) rethrows -> T {
        try $testOverride.withValue(enabled, operation: body)
    }

    /// Effective reduce-motion for SwiftUI modifiers: environment first, then task-local test override.
    public static func effectiveReduceMotionEnabled(accessibilityReduceMotion: Bool) -> Bool {
        if let testOverride {
            return testOverride
        }
        return accessibilityReduceMotion
    }
}

/// Suppresses implicit animations in this subtree when reduce motion is effective (GitHub #298).
public struct PlatformReduceMotionSubtreeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    public init() {}

    public func body(content: Content) -> some View {
        let reduceMotion = PlatformReduceMotionPreference.effectiveReduceMotionEnabled(
            accessibilityReduceMotion: accessibilityReduceMotion
        )
        return content.transaction { transaction in
            guard reduceMotion else { return }
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }
}

/// Imperative animation helper that skips `withAnimation` when reduce motion is enabled.
public func withPlatformAnimation<Result>(
    _ animation: PlatformAnimation = .easeInOut,
    _ body: () throws -> Result
) rethrows -> Result {
    if PlatformReduceMotionPreference.isReduceMotionEnabled {
        return try body()
    }
    return try withAnimation(animation.swiftUIAnimation, body)
}
