//
//  InputHandlingInteractions.swift
//  SixLayerFramework
//
//  Created for Phase 5: Framework Enhancement Areas - Input Handling & Interactions
//
//  This file provides comprehensive input handling and interaction patterns
//  that automatically adapt to different platforms and input methods.
//

import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

// MARK: - Input Handling & Interactions Manager

/// Manages input handling and interactions across platforms
public class InputHandlingManager: ObservableObject {
    
    /// Current platform being optimized for
    public let currentPlatform: SixLayerPlatform
    
    /// Current interaction patterns for the platform
    public let interactionPatterns: InteractionPatterns
    
    /// Keyboard shortcut manager
    public let keyboardManager: KeyboardShortcutManager
    
    /// Haptic feedback manager
    public let hapticManager: HapticFeedbackManager
    
    /// Drag and drop manager
    public let dragDropManager: DragDropManager
    
    public init(platform: SixLayerPlatform = .current) {
        self.currentPlatform = platform
        self.interactionPatterns = InteractionPatterns(for: platform)
        self.keyboardManager = KeyboardShortcutManager(for: platform)
        self.hapticManager = HapticFeedbackManager(for: platform)
        self.dragDropManager = DragDropManager(for: platform)
    }
    
    /// Get platform-appropriate interaction behavior
        func getInteractionBehavior(for gesture: GestureType) -> InteractionBehavior {
        return InteractionBehavior(
            platform: currentPlatform,
            gesture: gesture,
            patterns: interactionPatterns
        )
    }
}

// MARK: - Interaction Behavior

/// Defines how interactions should behave on different platforms
public struct InteractionBehavior {
    public let platform: SixLayerPlatform
    public let gesture: GestureType
    public let patterns: InteractionPatterns
    
    /// Whether this gesture is supported on the current platform
    public var isSupported: Bool {
        return patterns.gestureSupport.contains(gesture)
    }
    
    /// The appropriate input method for this gesture
    public var inputMethod: InputType {
        switch gesture {
        case .tap, .swipe, .pinch, .rotate, .longPress:
            return .touch
        case .click, .drag, .scroll, .rightClick:
            return .mouse
        case .spatial, .eyeTracking:
            return .gesture
        }
    }
    
    /// Whether haptic feedback should be provided
    public var shouldProvideHapticFeedback: Bool {
        return platform == .iOS && inputMethod == .touch
    }
    
    /// Whether sound feedback should be provided
    public var shouldProvideSoundFeedback: Bool {
        return platform == .macOS && inputMethod == .mouse
    }
}

// MARK: - Keyboard Shortcut Manager

/// Manages keyboard shortcuts with platform-appropriate behavior
public class KeyboardShortcutManager {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Create a platform-appropriate keyboard shortcut
        func createShortcut(
        key: KeyEquivalent,
        modifiers: EventModifiers = .command,
        action: @escaping () -> Void
    ) -> KeyboardShortcut {
        let platformModifiers = adaptModifiersForPlatform(modifiers)
        return KeyboardShortcut(key, modifiers: platformModifiers)
    }
    
    /// Adapt modifiers for platform conventions
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
    private func adaptModifiersForPlatform(_ modifiers: EventModifiers) -> EventModifiers {
        return platform.defaultKeyboardModifiers(modifiers)
    }
    
    /// Get platform-appropriate shortcut description
    /// Uses PlatformStrategy to reduce code duplication (Issue #140)
        func getShortcutDescription(key: KeyEquivalent, modifiers: EventModifiers = .command) -> String {
        return platform.defaultShortcutDescription(key: key, modifiers: modifiers)
    }
    
    private func getModifierString(_ modifiers: EventModifiers) -> String {
        var result = ""
        if modifiers.contains(.command) { result += "⌘" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.shift) { result += "⇧" }
        return result
    }
}

// MARK: - Haptic Feedback Manager

/// Manages haptic feedback with platform-appropriate behavior
public class HapticFeedbackManager {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Trigger haptic feedback appropriate for the platform
    @MainActor func triggerFeedback(_ feedback: PlatformHapticFeedback) {
        switch platform {
        case .iOS:
            #if os(iOS)
            triggerIOSFeedback(feedback)
            #endif
        case .macOS:
            #if os(macOS)
            triggerMacOSFeedback(feedback)
            #endif
        case .watchOS:
            triggerWatchOSFeedback(feedback)
        case .tvOS:
            // tvOS doesn't support haptic feedback
            break
        case .visionOS:
            // visionOS supports spatial haptics
            triggerVisionOSFeedback(feedback)
        }
    }
    
    #if os(iOS)
    @MainActor private func triggerIOSFeedback(_ feedback: PlatformHapticFeedback) {
        switch feedback {
        case .light:
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        case .medium:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .heavy:
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        case .soft:
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
        case .rigid:
            let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
            impactFeedback.impactOccurred()
        case .success:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
    #endif
    
    #if os(macOS)
    private func triggerMacOSFeedback(_ feedback: PlatformHapticFeedback) {
        // macOS provides sound feedback instead of haptic feedback
        switch feedback {
        case .light, .soft:
            NSSound.beep()
        case .medium:
            NSSound.beep()
        case .heavy, .rigid:
            NSSound.beep()
        case .success:
            NSSound.beep()
        case .warning:
            NSSound.beep()
        case .error:
            NSSound.beep()
        }
    }
    #endif
    
    private func triggerWatchOSFeedback(_ feedback: PlatformHapticFeedback) {
        // watchOS has limited haptic feedback capabilities
        // This would need to be implemented with WatchKit
    }
    
    private func triggerVisionOSFeedback(_ feedback: PlatformHapticFeedback) {
        // visionOS supports spatial haptic feedback
        // This would need to be implemented with visionOS APIs
    }
}

// MARK: - Drag and Drop Manager

/// Manages drag and drop operations with platform-appropriate behavior
public class DragDropManager {
    public let platform: SixLayerPlatform
    
    public init(for platform: SixLayerPlatform) {
        self.platform = platform
    }
    
    /// Get platform-appropriate drag behavior
        func getDragBehavior() -> DragBehavior {
        switch platform {
        case .iOS:
            return DragBehavior(
                supportsDrag: true,
                supportsDrop: true,
                dragPreview: .platform,
                dropIndicator: .platform
            )
        case .macOS:
            return DragBehavior(
                supportsDrag: true,
                supportsDrop: true,
                dragPreview: .custom,
                dropIndicator: .custom
            )
        case .watchOS:
            return DragBehavior(
                supportsDrag: false,
                supportsDrop: false,
                dragPreview: .none,
                dropIndicator: .none
            )
        case .tvOS:
            return DragBehavior(
                supportsDrag: false,
                supportsDrop: false,
                dragPreview: .none,
                dropIndicator: .none
            )
        case .visionOS:
            return DragBehavior(
                supportsDrag: true,
                supportsDrop: true,
                dragPreview: .spatial,
                dropIndicator: .spatial
            )
        }
    }
}

/// Defines drag and drop behavior for a platform
public struct DragBehavior {
    public let supportsDrag: Bool
    public let supportsDrop: Bool
    public let dragPreview: DragPreviewStyle
    public let dropIndicator: DropIndicatorStyle
}

public enum DragPreviewStyle {
    case none
    case platform
    case custom
    case spatial
}

public enum DropIndicatorStyle {
    case none
    case platform
    case custom
    case spatial
}

// MARK: - View Extensions for Input Handling

public extension View {
    
    /// Apply platform-appropriate input handling to a view
    func platformInputHandling() -> some View {
        let manager = InputHandlingManager()
        return self
            .environmentObject(manager)
            .platformKeyboardShortcuts(manager: manager.keyboardManager)
            .platformHapticFeedback(manager: manager.hapticManager)
            .platformDragDrop(manager: manager.dragDropManager)
    }
    
    /// Apply platform-appropriate keyboard shortcuts
    func platformKeyboardShortcuts(
        manager: KeyboardShortcutManager
    ) -> some View {
        #if os(macOS)
        return self
            .keyboardShortcut(.init("s"), modifiers: .command)
            .keyboardShortcut(.init("n"), modifiers: .command)
            .keyboardShortcut(.init("o"), modifiers: .command)
        #else
        return self
        #endif
    }
    
    /// Apply platform-appropriate haptic feedback
    func platformHapticFeedback(
        manager: HapticFeedbackManager
    ) -> some View {
        return self
            .onTapGesture {
                manager.triggerFeedback(.light)
            }
            .onLongPressGesture {
                manager.triggerFeedback(.medium)
            }
    }
    
    /// Apply platform-appropriate drag and drop
    func platformDragDrop(
        manager: DragDropManager
    ) -> some View {
        let behavior = manager.getDragBehavior()
        
        return Group {
            if behavior.supportsDrag && behavior.supportsDrop {
                self
                    .platformOnDropFiles { providers in
                        // Handle file drops
                        return true
                    }
            } else {
                self
            }
        }
    }
}

// MARK: - Touch vs Mouse Interaction Extensions

public extension View {
    
    /// Apply platform-appropriate touch/mouse interactions
    func platformTouchMouseInteraction(
        onTap: @escaping () -> Void = {},
        onLongPress: @escaping () -> Void = {},
        onRightClick: @escaping () -> Void = {}
    ) -> some View {
        let manager = InputHandlingManager()
        let behavior = manager.getInteractionBehavior(for: .tap)
        
        return self
            .onTapGesture {
                if behavior.shouldProvideHapticFeedback {
                    manager.hapticManager.triggerFeedback(.light)
                }
                onTap()
            }
            .onLongPressGesture {
                if behavior.shouldProvideHapticFeedback {
                    manager.hapticManager.triggerFeedback(.medium)
                }
                onLongPress()
            }
            #if os(macOS)
            .onTapGesture(count: 2) {
                // Double-click for macOS
                onRightClick()
            }
            #endif
    }
    
    /// Apply platform-appropriate gesture recognition
    func platformGestureRecognition(
        onSwipe: @escaping (SwipeDirection) -> Void = { _ in },
        onPinch: @escaping (CGFloat) -> Void = { _ in },
        onRotate: @escaping (Double) -> Void = { _ in }
    ) -> some View {
        let manager = InputHandlingManager()
        let patterns = manager.interactionPatterns
        
        return self
            .conditionalGesture(
                condition: patterns.gestureSupport.contains(.swipe),
                gesture: DragGesture().onEnded { value in
                    let direction = SwipeDirection.fromDrag(value)
                    onSwipe(direction)
                }
            )
            .conditionalGesture(
                condition: patterns.gestureSupport.contains(.pinch),
                gesture: MagnificationGesture().onChanged { value in
                    onPinch(value)
                }
            )
            .conditionalGesture(
                condition: patterns.gestureSupport.contains(.rotate),
                gesture: RotationGesture().onChanged { value in
                    onRotate(value.degrees)
                }
            )
    }
    
    /// Helper to conditionally add gestures
    @ViewBuilder
    private func conditionalGesture<G: Gesture>(
        condition: Bool,
        gesture: G
    ) -> some View {
        if condition {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

// MARK: - Supporting Types

public enum SwipeDirection: Equatable {
    case left
    case right
    case up
    case down
    
    static func fromDrag(_ drag: DragGesture.Value) -> SwipeDirection {
        let translation = drag.translation
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        
        if absX > absY {
            return translation.width > 0 ? .right : .left
        } else {
            return translation.height > 0 ? .down : .up
        }
    }
}

// MARK: - Platform-Specific Interaction Components

/// Platform-specific interaction components that adapt to different input methods.
/// To have accessibility identifiers applied (per L1 pattern), pass `identifierName` and/or
/// `accessibilityLabel`; otherwise callers must use `.named("...")` for IDs.
public struct PlatformInteractionButton<Label: View>: View {
    let label: Label
    let action: () -> Void
    let style: InteractionButtonStyle
    let identifierName: String?
    let accessibilityLabel: String?
    
    @StateObject private var inputManager = InputHandlingManager()
    
    public init(
        style: InteractionButtonStyle = .adaptive,
        action: @escaping () -> Void,
        identifierName: String? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.style = style
        self.action = action
        self.identifierName = identifierName
        self.accessibilityLabel = accessibilityLabel
        self.label = label()
    }
    
    public var body: some View {
        Button(action: {
            // Provide appropriate feedback
            let behavior = inputManager.getInteractionBehavior(for: .tap)
            if behavior.shouldProvideHapticFeedback {
                inputManager.hapticManager.triggerFeedback(.light)
            }
            if behavior.shouldProvideSoundFeedback {
                inputManager.hapticManager.triggerFeedback(.light)
            }
            action()
        }) {
            label
                .padding()
                .background(backgroundColorForStyle(style))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .automaticCompliance(
            identifierName: identifierName.map(sanitizeLabelText),
            identifierElementType: "Button",
            accessibilityLabel: accessibilityLabel
        )
    }
    
    private func backgroundColorForStyle(_ style: InteractionButtonStyle) -> Color {
        switch style {
        case .adaptive:
            return Color.accentColor
        case .primary:
            return Color.blue
        case .secondary:
            return Color.gray
        case .destructive:
            return Color.red
        }
    }
}

public enum InteractionButtonStyle {
    case adaptive
    case primary
    case secondary
    case destructive
}

// Simplified button implementation without custom ButtonStyle
// This avoids the compilation issues with ButtonStyle protocol
