import Foundation

/// How L4 should chrome a sidebar presented as a sheet (#447).
public enum PlatformSidebarSheetChrome: Equatable {
    /// Wrap in `NavigationStack` (iOS).
    case navigationStackWrapped
    /// Apply a small presentation frame (macOS).
    case presentationFramed
    /// Pass through (tvOS / watchOS / visionOS).
    case unmodified
}

/// Deliberately wrong mapping so #447 tests fail at runtime.
public func platformSidebarSheetChrome(for platform: SixLayerPlatform) -> PlatformSidebarSheetChrome {
    .unmodified
}
