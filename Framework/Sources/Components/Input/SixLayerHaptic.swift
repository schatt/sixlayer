import Foundation
#if os(iOS)
import UIKit
#endif

/// Shared haptic resolution used by View modifiers, L5, HIG, and `HapticFeedbackManager`.
enum SixLayerHaptic {
    /// Returns the style to fire, or `nil` when haptics are not supported.
    static func resolvedFeedback(
        _ requested: PlatformHapticFeedback,
        supported: Bool
    ) -> PlatformHapticFeedback? {
        supported ? requested : nil
    }

    /// Fires platform haptic feedback when the capability is present; no-op otherwise.
    @MainActor
    static func trigger(_ requested: PlatformHapticFeedback) {
        guard let feedback = resolvedFeedback(
            requested,
            supported: RuntimeCapabilityDetection.supportsHapticFeedback
        ) else {
            return
        }
        fire(feedback)
    }

    @MainActor
    private static func fire(_ feedback: PlatformHapticFeedback) {
        #if os(iOS)
        switch feedback {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}

#if os(iOS)
extension IOSHapticStyle {
    /// Maps L5 styles onto the app-facing `PlatformHapticFeedback` enum.
    var platformHapticFeedback: PlatformHapticFeedback {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }
}
#endif
