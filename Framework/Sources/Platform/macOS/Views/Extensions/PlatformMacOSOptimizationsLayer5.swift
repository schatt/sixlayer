//
//  PlatformMacOSOptimizationsLayer5.swift
//  SixLayerFramework
//
//  Layer 5: macOS-specific chrome adapters (#451).
//  View-level `presentedWindowToolbarStyle(.unified)` — not Scene `windowToolbarStyle`.
//

import SwiftUI

/// How L5 chromes a macOS window toolbar.
public enum PlatformMacOSWindowToolbarChrome: Equatable {
    /// Apply unified presented window toolbar style (macOS).
    case unified
    /// Pass through (iOS / tvOS / watchOS / visionOS).
    case unmodified
}

/// Platform decision for macOS window-toolbar chrome. L5 applies the result.
public func platformMacOSWindowToolbarChrome(for platform: SixLayerPlatform) -> PlatformMacOSWindowToolbarChrome {
    switch platform {
    case .macOS:
        return .unified
    case .iOS, .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}

public extension View {
    /// Unified presented window toolbar on macOS; identity elsewhere.
    @MainActor
    @ViewBuilder
    func platformMacOSWindowToolbar_L5() -> some View {
        #if os(macOS)
        switch platformMacOSWindowToolbarChrome(for: .macOS) {
        case .unified:
            self.presentedWindowToolbarStyle(.unified)
        case .unmodified:
            self
        }
        #else
        self
        #endif
    }
}

/// How L5 chromes keyboard-focus affordance on macOS.
public enum PlatformMacOSKeyboardFocusChrome: Equatable {
    /// Apply SwiftUI `.focusable()` (macOS).
    case focusable
    /// Pass through (iOS / tvOS / watchOS / visionOS).
    case unmodified
}

/// Platform decision for macOS keyboard-focus chrome. L5 applies the result.
public func platformMacOSKeyboardFocusChrome(for platform: SixLayerPlatform) -> PlatformMacOSKeyboardFocusChrome {
    switch platform {
    case .macOS:
        return .focusable
    case .iOS, .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}

public extension View {
    /// Keyboard-focus affordance on macOS; identity elsewhere.
    /// Uses SwiftUI `.focusable()` (macOS 12+). NavigationStack keyboard product stays on #446.
    @MainActor
    @ViewBuilder
    func platformMacOSKeyboardFocus_L5() -> some View {
        #if os(macOS)
        switch platformMacOSKeyboardFocusChrome(for: .macOS) {
        case .focusable:
            self.focusable()
        case .unmodified:
            self
        }
        #else
        self
        #endif
    }
}
