import SwiftUI

/// When to show ``View/platformNavigationSheetButton(action:sidebarVisibility:)`` in app chrome (issue #323).
public enum PlatformNavigationSheetButtonVisibilityPolicy: Sendable, Equatable {
    /// Legacy behavior: always include the control in the layout.
    case always
    /// iOS: phone and CarPlay, or split column `.detailOnly`; macOS: always (sidebar toggle).
    case phoneOrDetailOnly
}

/// Pure visibility rules for the navigation sheet / sidebar toolbar control.
public enum PlatformNavigationSheetButtonVisibility {
    public static func shouldShow(
        policy: PlatformNavigationSheetButtonVisibilityPolicy,
        deviceType: DeviceType,
        columnVisibility: NavigationSplitViewVisibility?
    ) -> Bool {
        // Deliberate stub for TDD red (#323).
        _ = policy
        _ = deviceType
        _ = columnVisibility
        return false
    }
}
