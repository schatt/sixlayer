import SwiftUI

// MARK: - Navigation sheet toolbar visibility (issue #323)

/// When to show ``View/platformNavigationSheetButton(action:sidebarVisibility:visibility:columnVisibility:systemImage:accessibilityIdentifier:)`` in app chrome (issue #323).
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
        switch policy {
        case .always:
            return true
        case .phoneOrDetailOnly:
            if deviceType == .mac {
                return true
            }
            if deviceType == .phone || deviceType == .car {
                return true
            }
            if columnVisibility == .detailOnly {
                return true
            }
            return false
        }
    }
}
