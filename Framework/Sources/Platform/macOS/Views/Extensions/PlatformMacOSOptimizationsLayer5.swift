//
//  PlatformMacOSOptimizationsLayer5.swift
//  SixLayerFramework
//
//  Layer 5: macOS-specific chrome adapters (#451).
//  View-level `.toolbarStyle(.browser)` — not Scene `windowToolbarStyle`.
//

import SwiftUI

/// How L5 chromes a macOS toolbar.
public enum PlatformMacOSToolbarChrome: Equatable {
    /// Apply browser toolbar style (macOS).
    case browser
    /// Pass through (iOS / tvOS / watchOS / visionOS).
    case unmodified
}

/// Platform decision for macOS toolbar chrome. Intentionally wrong until green.
public func platformMacOSToolbarChrome(for platform: SixLayerPlatform) -> PlatformMacOSToolbarChrome {
    switch platform {
    case .iOS, .macOS, .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}

public extension View {
    /// Browser toolbar style on macOS; identity elsewhere.
    @MainActor
    func platformMacOSToolbar_L5() -> some View {
        self
    }
}
