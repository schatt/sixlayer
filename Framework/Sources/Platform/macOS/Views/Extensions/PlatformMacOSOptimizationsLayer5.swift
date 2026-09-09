//
//  PlatformMacOSOptimizationsLayer5.swift
//  SixLayerFramework
//
//  Layer 5: macOS-specific chrome adapters (#451).
//

import SwiftUI

/// How L5 chromes a macOS window toolbar.
public enum PlatformMacOSWindowToolbarChrome: Equatable {
    /// Apply unified window toolbar style (macOS).
    case unified
    /// Pass through (iOS / tvOS / watchOS / visionOS).
    case unmodified
}

/// Platform decision for macOS window-toolbar chrome. Intentionally wrong until green.
public func platformMacOSWindowToolbarChrome(for platform: SixLayerPlatform) -> PlatformMacOSWindowToolbarChrome {
    switch platform {
    case .iOS, .macOS, .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}

public extension View {
    /// Unified window toolbar on macOS; identity elsewhere.
    @MainActor
    func platformMacOSWindowToolbar_L5() -> some View {
        self
    }
}
