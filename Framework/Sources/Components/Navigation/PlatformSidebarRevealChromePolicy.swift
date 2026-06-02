import SwiftUI

/// Policy for split-edge sidebar reveal chrome (#324). Intentionally incorrect stub for TDD red.
public enum PlatformSidebarRevealChromePolicy {
    public static func showsAffordance(for visibility: NavigationSplitViewVisibility) -> Bool {
        visibility != .detailOnly
    }

    public static func visibilityAfterReveal() -> NavigationSplitViewVisibility {
        .detailOnly
    }

    public static func shouldApplyRevealGesture(for visibility: NavigationSplitViewVisibility) -> Bool {
        showsAffordance(for: visibility)
    }

    public static func pullIndicatorIsVisible(columnVisibility: Binding<NavigationSplitViewVisibility>) -> Bool {
        !showsAffordance(for: columnVisibility.wrappedValue)
    }
}
