import Foundation

/// Shared haptic resolution for View modifiers, L5, HIG, and `HapticFeedbackManager`.
/// Deliberately wrong gate/mapping until #445 tests fail for the right reason.
enum SixLayerHaptic {
    /// Returns the style to fire, or `nil` when haptics are not supported.
    static func resolvedFeedback(
        _ requested: PlatformHapticFeedback,
        supported: Bool
    ) -> PlatformHapticFeedback? {
        requested
    }
}

#if os(iOS)
extension IOSHapticStyle {
    /// Maps L5 styles onto the app-facing `PlatformHapticFeedback` enum.
    var platformHapticFeedback: PlatformHapticFeedback {
        .light
    }
}
#endif
