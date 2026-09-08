import SwiftUI

// MARK: - Platform Haptic Feedback Extensions

/// App-facing haptic styles. Use `View.platformHapticFeedback(_:)` as the public
/// View API; L5 `platformIOSHapticFeedback` / `IOSHapticStyle` are deprecated wrappers (#445).
public enum PlatformHapticFeedback: CaseIterable {
    /// Light impact feedback - subtle tactile response
    case light
    /// Medium impact feedback - moderate tactile response
    case medium
    /// Heavy impact feedback - strong tactile response
    case heavy
    /// Soft impact feedback - gentle tactile response
    case soft
    /// Rigid impact feedback - sharp tactile response
    case rigid
    /// Success notification feedback - positive completion
    case success
    /// Warning notification feedback - caution indication
    case warning
    /// Error notification feedback - error indication
    case error
}

// MARK: - Haptic Feedback View Modifiers

/// View modifier that triggers haptic feedback on tap
private struct PlatformHapticFeedbackTapModifier: ViewModifier {
    let feedback: PlatformHapticFeedback
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                Task { @MainActor in
                    SixLayerHaptic.trigger(feedback)
                }
            }
    }
}

/// View modifier that triggers haptic feedback and executes action on tap
private struct PlatformHapticFeedbackWithActionModifier: ViewModifier {
    let feedback: PlatformHapticFeedback
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                Task { @MainActor in
                    SixLayerHaptic.trigger(feedback)
                }
                action()
            }
    }
}

/// Platform-specific haptic feedback extensions that provide consistent behavior
/// across iOS and macOS while handling platform differences appropriately
public extension View {

    /// Primary View API for haptic feedback (#445).
    /// iOS: fires on tap when `RuntimeCapabilityDetection.supportsHapticFeedback`;
    /// other platforms: no-op.
    ///
    /// - Parameter feedback: The type of haptic feedback to trigger
    /// - Returns: The view with haptic feedback on tap
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Tap me") { }
    ///     .platformHapticFeedback(.light)
    /// ```
    ///
    /// **Note**: Haptic feedback triggers when the view is tapped, not when the modifier is applied.
    func platformHapticFeedback(_ feedback: PlatformHapticFeedback) -> some View {
        self
            .modifier(PlatformHapticFeedbackTapModifier(feedback: feedback))
            .automaticCompliance()
    }

    /// Primary View API for haptic feedback plus a tap action (#445).
    /// iOS: fires haptics on tap when supported; other platforms: action only.
    ///
    /// - Parameters:
    ///   - feedback: The type of haptic feedback to trigger
    ///   - action: The action to execute after haptic feedback
    /// - Returns: The view with haptic feedback and action on tap
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Save") {
    ///     save()
    /// }
    /// .platformHapticFeedback(.success) {
    ///     print("Save completed")
    /// }
    /// ```
    ///
    /// **Note**: Haptic feedback and action trigger when the view is tapped, not when the modifier is applied.
    func platformHapticFeedback(
        _ feedback: PlatformHapticFeedback,
        action: @escaping () -> Void
    ) -> some View {
        self
            .modifier(PlatformHapticFeedbackWithActionModifier(feedback: feedback, action: action))
            .automaticCompliance()
    }
}
