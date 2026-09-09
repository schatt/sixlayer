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

/// Platform decision for sidebar-sheet chrome. L4/L6 apply the result; they do not re-fork `#if os`.
public func platformSidebarSheetChrome(for platform: SixLayerPlatform) -> PlatformSidebarSheetChrome {
    switch platform {
    case .iOS:
        return .navigationStackWrapped
    case .macOS:
        return .presentationFramed
    case .tvOS, .watchOS, .visionOS:
        return .unmodified
    }
}
