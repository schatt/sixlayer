import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Platform iOS Optimizations Layer 5: Platform-Specific Enhancements
/// This layer provides iOS-specific optimizations and enhancements that
/// leverage iOS platform capabilities. This layer handles platform-specific
/// features like haptics, iOS-specific navigation, and iOS-only UI patterns.

/// Direction recognized by `platformIOSSwipeGestures` thresholds (±100 primary, ±50 reject band).
public enum PlatformIOSSwipeDirection: Equatable {
    case left
    case right
    case up
    case down
}

/// Pure threshold decision for `platformIOSSwipeGestures` (unit-testable; #424).
/// Primary axis must exceed ±100; cross-axis must stay inside ±50 reject band.
public func platformIOSSwipeDirection(from translation: CGSize) -> PlatformIOSSwipeDirection? {
    let width = translation.width
    let height = translation.height
    if width < -100 && abs(height) < 50 {
        return .left
    }
    if width > 100 && abs(height) < 50 {
        return .right
    }
    if height < -100 && abs(width) < 50 {
        return .up
    }
    if height > 100 && abs(width) < 50 {
        return .down
    }
    return nil
}

/// `isRefreshing` true → `onRefresh` → false sequence used by `platformIOSPullToRefresh` (#424).
public func platformIOSPullToRefreshSequence(
    setRefreshing: (Bool) -> Void,
    onRefresh: () -> Void
) {
    setRefreshing(true)
    onRefresh()
    setRefreshing(false)
}

public extension View {
    
    /// Platform-specific iOS navigation bar with consistent styling
    /// Provides iOS-specific navigation bar appearance and behavior
    #if os(iOS)
    func platformIOSNavigationBar(
        title: String? = nil,
        displayMode: NavigationBarItem.TitleDisplayMode = .automatic
    ) -> some View {
        self.navigationBarTitle(title ?? "", displayMode: displayMode)
    }
    #else
    func platformIOSNavigationBar(
        title: String? = nil
    ) -> some View {
        self
    }
    #endif
    
    /// Platform-specific iOS toolbar with consistent styling
    /// Provides iOS-specific toolbar appearance and behavior
    func platformIOSToolbar<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        return self.toolbar {
            content()
        }
    }
    
    /// Platform-specific iOS swipe gestures with consistent behavior
    /// Provides iOS-specific swipe gesture handling
    func platformIOSSwipeGestures(
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        onSwipeDown: (() -> Void)? = nil
    ) -> some View {
        #if os(iOS)
        self.gesture(
            DragGesture()
                .onEnded { value in
                    switch platformIOSSwipeDirection(from: value.translation) {
                    case .left:
                        onSwipeLeft?()
                    case .right:
                        onSwipeRight?()
                    case .up:
                        onSwipeUp?()
                    case .down:
                        onSwipeDown?()
                    case nil:
                        break
                    }
                }
        )
        #else
        // DragGesture-based swipe helpers are unavailable on tvOS (#237).
        self
        #endif
    }
    
    /// Platform-specific iOS haptic feedback with consistent behavior
    /// Provides iOS-specific haptic feedback patterns
    #if os(iOS)
    func platformIOSHapticFeedback(
        style: IOSHapticStyle = .light,
        onTrigger trigger: Bool = true
    ) -> some View {
        return self.onChange(of: trigger) {
            let impactFeedback: UIImpactFeedbackGenerator
            
            switch style {
            case .light:
                impactFeedback = UIImpactFeedbackGenerator(style: .light)
            case .medium:
                impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            case .heavy:
                impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            case .success:
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                return
            case .warning:
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
                return
            case .error:
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                return
            }
            
            impactFeedback.impactOccurred()
        }
    }
    #else
    func platformIOSHapticFeedback(
        style: Any = "light",
        onTrigger trigger: Bool = true
    ) -> some View {
        return self
    }
    #endif
    
    /// Platform-specific iOS accessibility with consistent behavior
    /// Provides iOS-specific accessibility enhancements
    func platformIOSAccessibility(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits? = nil
    ) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits ?? [])
    }
    
    /// Platform-specific iOS animations with consistent behavior
    /// Provides iOS-specific animation patterns
    #if os(iOS)
    func platformIOSAnimation(
        type: IOSAnimationType = .spring,
        duration: Double = 0.3
    ) -> some View {
        let animation: Animation
        
        switch type {
        case .spring:
            animation = .spring(response: duration, dampingFraction: 0.8, blendDuration: 0)
        case .easeIn:
            animation = .easeIn(duration: duration)
        case .easeOut:
            animation = .easeOut(duration: duration)
        case .easeInOut:
            animation = .easeInOut(duration: duration)
        case .linear:
            animation = .linear(duration: duration)
        }
        
        return self.animation(animation, value: UUID())
    }
    #else
    func platformIOSAnimation(
        type: Any = "spring",
        duration: Double = 0.3
    ) -> some View {
        return self
    }
    #endif
    
/// Platform-specific iOS layout with consistent behavior.
/// Applies safe-area region ignoring; does not subscribe to keyboard notifications
/// (empty keyboardAware / onReceive hooks removed — #444).
func platformIOSLayout(
    safeAreaInsets: Bool = true
) -> some View {
    #if os(iOS)
    self
        .ignoresSafeArea(safeAreaInsets ? .keyboard : .all, edges: .bottom)
    #else
    self
    #endif
}

    /// Platform-specific iOS pull-to-refresh with consistent behavior
    /// Provides iOS-specific pull-to-refresh functionality
    func platformIOSPullToRefresh(
        isRefreshing: Binding<Bool>,
        onRefresh: @escaping () -> Void
    ) -> some View {
        return self.refreshable {
            platformIOSPullToRefreshSequence(
                setRefreshing: { isRefreshing.wrappedValue = $0 },
                onRefresh: onRefresh
            )
        }
    }
    
    /// Platform-specific iOS context menu with consistent behavior
    /// Provides iOS-specific context menu functionality
    func platformIOSContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        return self.contextMenu {
            menuItems()
        }
    }
}

#if os(iOS)
/// iOS-specific haptic feedback styles
public enum IOSHapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

/// iOS-specific animation types
public enum IOSAnimationType {
    case spring
    case easeIn
    case easeOut
    case easeInOut
    case linear
}
#endif