import SwiftUI

/// Platform-specific navigation title display mode
///
/// Cross-platform abstraction for navigation bar title display modes.
/// Use this enum with `platformNavigationTitleDisplayMode()` to eliminate
/// platform-specific conditional compilation.
///
/// ## Available Modes
///
/// - `.inline` - Compact inline title (iOS only, no-op on macOS)
/// - `.large` - Large title style (iOS only, no-op on macOS)
/// - `.automatic` - Platform-determined style (iOS only, no-op on macOS)
///
/// ## Usage
///
/// ```swift
/// Text("Content")
///     .platformNavigationTitle_L4("My Title")
///     .platformNavigationTitleDisplayMode_L4(.inline)
/// ```
///
/// This eliminates the need for:
/// ```swift
/// #if os(iOS)
/// .navigationBarTitleDisplayMode(.inline)
/// #endif
/// ```
public enum PlatformTitleDisplayMode {
    case inline
    case large
    case automatic

    #if os(iOS)
    var navigationBarDisplayMode: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .inline: return .inline
        case .large: return .large
        case .automatic: return .automatic
        }
    }
    #elseif os(macOS)
    var navigationBarDisplayMode: Any { self }
    #endif
}

/// Legacy iOS presentation-detent wrapper.
///
/// - Warning: Prefer ``PlatformPresentationSize`` (`.small` / `.medium` / `.large` /
///   `.exact(width:height:)`) on sheet and popover APIs (#384). Detents are an iOS-only
///   projection of those size hints; this enum has no `.small` and height-only `.custom`.
@available(*, deprecated, message: "Use PlatformPresentationSize (.small/.medium/.large/.exact) instead of PlatformPresentationDetent")
public enum PlatformPresentationDetent {
    case medium
    case large
    case custom(CGFloat)

    #if os(iOS)
    @available(iOS 16.0, *)
    var presentationDetent: PresentationDetent {
        switch self {
        case .medium: return .medium
        case .large: return .large
        case .custom(let height): return .height(height)
        }
    }
    #endif

    /// Bridge to the preferred size vocabulary (height-only custom → square exact).
    public var asPresentationSize: PlatformPresentationSize {
        switch self {
        case .medium:
            return .medium
        case .large:
            return .large
        case .custom(let height):
            return .exact(width: height, height: height)
        }
    }
}

public struct PlatformTabItem: Identifiable, Hashable {
    public let id: UUID = UUID()
    public let title: String
    public let systemImage: String?

    public init(title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }
}
