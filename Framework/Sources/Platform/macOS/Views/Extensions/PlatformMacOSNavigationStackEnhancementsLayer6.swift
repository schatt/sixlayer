//
//  PlatformMacOSNavigationStackEnhancementsLayer6.swift
//  SixLayerFramework
//
//  Layer 6: macOS NavigationStack keyboard-first navigation (#446).
//  Verified SwiftUI View APIs: `focusSection()`, `defaultFocus(_::)`, `onExitCommand`,
//  `keyboardShortcut`. Scene `commands` cannot be a View L6 adapter.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Decisions

/// How L6 chromes a macOS NavigationStack for keyboard-first navigation.
public enum PlatformMacOSNavigationStackKeyboardChrome: Equatable, Sendable {
    /// Focus section, presented-nav exit/cancel, honest traits (macOS).
    case keyboardFirst
    /// Pass through (iOS / tvOS / watchOS / visionOS).
    case unmodified
}

/// Which list ↔ detail pane should receive default focus.
public enum PlatformMacOSNavigationFocusPane: Equatable, Sendable {
    case list
    case detail
}

/// View-level navigation actions that map to SDK `KeyboardShortcut` values.
/// Scene-level `commands` is not applied here — that API is `Scene`-only.
public enum PlatformMacOSNavigationKeyboardAction: Equatable, Sendable {
    case back
    case select
    case dismiss
}

/// Extractable shortcut kind. Mapped to `KeyboardShortcut` on platforms that have it.
public enum PlatformMacOSNavigationKeyboardShortcutKind: Equatable, Sendable {
    /// Command + `[` (Safari / Finder-style back).
    case commandLeftBracket
    /// `KeyboardShortcut.defaultAction` (Return).
    case defaultAction
    /// `KeyboardShortcut.cancelAction` (Escape).
    case cancelAction
}

/// Platform decision for macOS NavigationStack keyboard chrome. L6 applies the result.
public func platformMacOSNavigationStackKeyboardChrome(
    for platform: SixLayerPlatform
) -> PlatformMacOSNavigationStackKeyboardChrome {
    // Deliberately wrong until green (#446 TDD red).
    return .unmodified
}

/// Default-focus pane for list ↔ detail. Detail presented → detail; otherwise list.
public func platformMacOSNavigationDefaultFocusPane(
    isDetailPresented: Bool
) -> PlatformMacOSNavigationFocusPane {
    // Deliberately wrong until green (#446 TDD red).
    return .list
}

/// Resolved default-focus value for the given pane.
public func platformMacOSNavigationDefaultFocusValue<Value>(
    pane: PlatformMacOSNavigationFocusPane,
    list: Value,
    detail: Value
) -> Value {
    // Deliberately wrong until green (#446 TDD red).
    return list
}

/// Escape / `onExitCommand` should dismiss only when the stack is presented.
public func platformMacOSNavigationShouldDismissOnExit(isPresented: Bool) -> Bool {
    // Deliberately wrong until green (#446 TDD red).
    return false
}

/// Shortcut kind for a navigation action. Scene `commands` is not used.
public func platformMacOSNavigationKeyboardShortcutKind(
    for action: PlatformMacOSNavigationKeyboardAction
) -> PlatformMacOSNavigationKeyboardShortcutKind {
    // Deliberately wrong until green (#446 TDD red).
    return .cancelAction
}

#if os(iOS) || os(macOS) || os(visionOS)
/// SDK `KeyboardShortcut` for a navigation action (iOS / macOS / visionOS).
public func platformMacOSNavigationKeyboardShortcut(
    for action: PlatformMacOSNavigationKeyboardAction
) -> KeyboardShortcut {
    switch platformMacOSNavigationKeyboardShortcutKind(for: action) {
    case .commandLeftBracket:
        return KeyboardShortcut("[", modifiers: .command)
    case .defaultAction:
        return .defaultAction
    case .cancelAction:
        return .cancelAction
    }
}
#endif

// MARK: - View modifiers

/// Applies SwiftUI `focusSection()` so the stack is a keyboard focus region.
public struct PlatformMacOSNavigationFocusSectionModifier: ViewModifier {
    public func body(content: Content) -> some View {
        #if os(macOS)
        content.focusSection()
        #else
        content
        #endif
    }
}

/// Applies `onExitCommand` → `dismiss()` when the stack is presented.
public struct PlatformMacOSNavigationExitCommandModifier: ViewModifier {
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss

    public func body(content: Content) -> some View {
        #if os(macOS)
        content.onExitCommand {
            if platformMacOSNavigationShouldDismissOnExit(isPresented: isPresented) {
                dismiss()
            }
        }
        #else
        content
        #endif
    }
}

/// View-level `keyboardShortcut` buttons for back / select / dismiss.
/// Not Scene `commands`.
public struct PlatformMacOSNavigationKeyboardShortcutsModifier: ViewModifier {
    public var onBack: (() -> Void)?
    public var onSelect: (() -> Void)?
    public var onDismiss: (() -> Void)?

    public func body(content: Content) -> some View {
        // Identity stub until green — modifier must wrap on macOS.
        content
    }
}

/// Applies SwiftUI `defaultFocus` for list ↔ detail restore.
public struct PlatformMacOSNavigationListDetailFocusModifier<Value: Hashable>: ViewModifier {
    public var binding: FocusState<Value>.Binding
    public var value: Value

    public func body(content: Content) -> some View {
        #if os(macOS)
        content.defaultFocus(binding, value)
        #else
        content
        #endif
    }
}

public extension View {

    /// Apply macOS-specific enhancements to a NavigationStack.
    /// Keyboard-first: focus section + presented-nav exit. Does not duplicate L5
    /// `.focusable()` and does not mark every stack `.isHeader`.
    #if os(macOS)
    @MainActor
    func platformMacOSNavigationStackEnhancements_L6() -> some View {
        return self
            // Still the pre-#446 body so subject-type tests fail at runtime (TDD red).
            .focusable()
            .accessibilityAddTraits(.isHeader)
            .platformPresentationFrame(sizes: [.small])
    }
    #else
    func platformMacOSNavigationStackEnhancements_L6() -> some View {
        return self
    }
    #endif

    /// View-level keyboard shortcuts for back / select / dismiss.
    /// Scene `commands` is skipped — that API is not a View modifier.
    @MainActor
    func platformMacOSNavigationKeyboardShortcuts_L6(
        onBack: (() -> Void)? = nil,
        onSelect: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        // Identity stub until green — macOS must wrap with the named modifier.
        _ = (onBack, onSelect, onDismiss)
        return self
    }

    /// Apply SwiftUI `defaultFocus` for list ↔ detail using the resolved pane.
    @MainActor
    func platformMacOSNavigationListDetailFocus_L6<Value: Hashable>(
        _ binding: FocusState<Value>.Binding,
        list: Value,
        detail: Value,
        isDetailPresented: Bool
    ) -> some View {
        let pane = platformMacOSNavigationDefaultFocusPane(isDetailPresented: isDetailPresented)
        let value = platformMacOSNavigationDefaultFocusValue(pane: pane, list: list, detail: detail)
        return modifier(
            PlatformMacOSNavigationListDetailFocusModifier(binding: binding, value: value)
        )
    }
}
