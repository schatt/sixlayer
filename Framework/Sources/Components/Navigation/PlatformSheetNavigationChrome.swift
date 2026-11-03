import Foundation
import SwiftUI

/// How `platformSheet` chromes presented roots for navigation title / toolbar (#636).
public enum PlatformSheetNavigationChrome: Equatable {
    /// Wrap in `NavigationStack` (iOS and macOS).
    case navigationStackWrapped
    /// Pass through (tvOS / watchOS / visionOS).
    case unmodified
}

/// Platform decision for sheet-root navigation chrome.
/// Apply mirrors this table via compile-time `#if os` (not a runtime ViewBuilder switch).
public func platformSheetNavigationChrome(for platform: SixLayerPlatform) -> PlatformSheetNavigationChrome {
    switch platform {
    case .iOS, .macOS:
        return .navigationStackWrapped
    case .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}

public extension View {
    /// Sheet presented root: NavigationStack on iOS (and eventually macOS for #636 parity).
    /// Apply path must match `platformSheetNavigationChrome(for: .current)`.
    ///
    /// Deliberate red stub: macOS left unmodified until green implementation.
    @MainActor
    func platformSheetNavigationChrome() -> some View {
        #if os(iOS)
        NavigationStack {
            self
        }
        #else
        self
        #endif
    }
}
