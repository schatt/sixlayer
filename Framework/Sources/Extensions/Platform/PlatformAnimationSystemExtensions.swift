import SwiftUI

// MARK: - Platform Animation System Extensions

/// Platform-specific animation system extensions that provide consistent behavior
/// across iOS and macOS while handling platform differences appropriately
public extension View {

    /// Platform animation with default parameters
    /// iOS: Uses animation; macOS: Uses animation
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter animation: The type of animation to apply
    /// - Returns: A view with platform-appropriate animation behavior
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Animated")
    ///     .platformAnimation(.spring)
    /// ```
    @ViewBuilder
    func platformAnimation(_ animation: PlatformAnimation) -> some View {
        modifier(
            PlatformAnimationModifier(
                animation: animation.swiftUIAnimation,
                value: UUID()
            )
        )
    }

    /// Platform animation with custom duration
    /// iOS: Uses animation with duration; macOS: Uses animation with duration
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameters:
    ///   - animation: The type of animation to apply
    ///   - duration: The custom duration for the animation
    /// - Returns: A view with platform-appropriate animation behavior
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Animated")
    ///     .platformAnimation(.easeInOut, duration: 0.5)
    /// ```
    @ViewBuilder
    func platformAnimation(
        _ animation: PlatformAnimation,
        duration: Double
    ) -> some View {
        modifier(
            PlatformAnimationModifier(
                animation: animation.swiftUIAnimation(duration: duration),
                value: UUID()
            )
        )
    }

    /// Platform animation with spring parameters
    /// iOS: Uses animation with spring; macOS: Uses animation with spring
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameters:
    ///   - animation: The type of animation to apply
    ///   - response: The spring response value
    ///   - dampingFraction: The spring damping fraction
    ///   - blendDuration: The spring blend duration
    /// - Returns: A view with platform-appropriate animation behavior
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Spring Animated")
    ///     .platformAnimation(.spring, response: 0.5, dampingFraction: 0.8)
    /// ```
    @ViewBuilder
    func platformAnimation(
        _ animation: PlatformAnimation,
        response: Double,
        dampingFraction: Double,
        blendDuration: Double = 0
    ) -> some View {
        modifier(
            PlatformAnimationModifier(
                animation: animation.swiftUIAnimation(
                    response: response,
                    dampingFraction: dampingFraction,
                    blendDuration: blendDuration
                ),
                value: UUID()
            )
        )
    }
}

// MARK: - Platform Animation Modifier

private struct PlatformAnimationModifier: ViewModifier {
    let animation: Animation
    let value: AnyHashable
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    func body(content: Content) -> some View {
        let reduceMotion = accessibilityReduceMotion
            || PlatformReduceMotionPreference.isReduceMotionEnabled
        if let resolved = PlatformReduceMotionPreference.resolvedAnimation(
            animation,
            reduceMotionEnabled: reduceMotion
        ) {
            content.animation(resolved, value: value)
        } else {
            content.animation(.none, value: value)
        }
    }
}

// MARK: - Platform Animation Types

/// Platform-specific animation types that map to SwiftUI animations
public enum PlatformAnimation {
    case easeIn
    case easeOut
    case easeInOut
    case linear
    case spring
    case interactiveSpring

    
    /// Convert to SwiftUI animation
    var swiftUIAnimation: Animation {
        switch self {
        case .easeIn:
            return .easeIn
        case .easeOut:
            return .easeOut
        case .easeInOut:
            return .easeInOut
        case .linear:
            return .linear
        case .spring:
            return .spring()
        case .interactiveSpring:
            return .interactiveSpring()

        }
    }
    
    /// Convert to SwiftUI animation with duration
    func swiftUIAnimation(duration: Double) -> Animation {
        switch self {
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .linear:
            return .linear(duration: duration)
        case .spring:
            return .spring(duration: duration)
        case .interactiveSpring:
            return .interactiveSpring(duration: duration)

        }
    }
    
    /// Convert to SwiftUI animation with spring parameters
    func swiftUIAnimation(
        response: Double,
        dampingFraction: Double,
        blendDuration: Double = 0
    ) -> Animation {
        switch self {
        case .spring:
            return .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        case .interactiveSpring:
            return .interactiveSpring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)

        default:
            return .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
    }
}
