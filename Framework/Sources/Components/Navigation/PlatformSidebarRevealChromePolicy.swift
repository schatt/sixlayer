import SwiftUI

/// Policy for split-edge sidebar reveal chrome when ``NavigationSplitView`` is detail-only (#324).
///
/// **Platform behavior**
/// - **iOS:** leading-edge swipe can set ``NavigationSplitViewVisibility/all``; visual stripe when detail-only.
/// - **macOS:** visual stripe only (system resize / toolbar handles reveal).
/// - **Other platforms:** no gesture; affordance follows ``showsAffordance``.
public enum PlatformSidebarRevealChromePolicy {
    /// Whether the edge affordance should be visible for the given split visibility.
    public static func showsAffordance(for visibility: NavigationSplitViewVisibility) -> Bool {
        visibility.isExplicitDetailOnly
    }

    /// Visibility to apply after a successful reveal gesture.
    public static func visibilityAfterReveal() -> NavigationSplitViewVisibility {
        .all
    }

    /// Whether a coordinated leading-edge reveal gesture should be installed.
    public static func shouldApplyRevealGesture(for visibility: NavigationSplitViewVisibility) -> Bool {
        guard showsAffordance(for: visibility) else { return false }
        return SixLayerPlatform.current == .iOS
    }

    /// Pull-indicator visibility derived from a live ``NavigationSplitView`` visibility binding.
    public static func pullIndicatorIsVisible(columnVisibility: Binding<NavigationSplitViewVisibility>) -> Bool {
        showsAffordance(for: columnVisibility.wrappedValue)
    }

    /// Minimum horizontal translation (points) to treat as a reveal swipe on iOS.
    static let revealSwipeMinimumTranslation: CGFloat = 80

    /// Maximum vertical drift (points) allowed for a horizontal reveal swipe on iOS.
    static let revealSwipeMaximumVerticalDrift: CGFloat = 50
}
