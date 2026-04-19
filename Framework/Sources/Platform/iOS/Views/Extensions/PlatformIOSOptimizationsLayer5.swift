import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Platform iOS Optimizations Layer 5: Platform-Specific Enhancements
/// This layer provides iOS-specific optimizations and enhancements that
/// leverage iOS platform capabilities. This layer handles platform-specific
/// features like haptics, iOS-specific navigation, and iOS-only UI patterns.

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
        self
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -100 && abs(value.translation.height) < 50 {
                            onSwipeLeft?()
                        }
                    }
            )
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 && abs(value.translation.height) < 50 {
                            onSwipeRight?()
                        }
                    }
            )
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height < -100 && abs(value.translation.width) < 50 {
                            onSwipeUp?()
                        }
                    }
            )
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 100 && abs(value.translation.width) < 50 {
                            onSwipeDown?()
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
    
    /// Platform-specific iOS layout with consistent behavior
    /// Provides iOS-specific layout optimizations
    func platformIOSLayout(
        safeAreaInsets: Bool = true,
        keyboardAware: Bool = false
    ) -> some View {
        #if os(iOS)
        self
            .ignoresSafeArea(safeAreaInsets ? .keyboard : .all, edges: .bottom)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                // Handle keyboard appearance
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // Handle keyboard dismissal
            }
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
            isRefreshing.wrappedValue = true
            onRefresh()
            isRefreshing.wrappedValue = false
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