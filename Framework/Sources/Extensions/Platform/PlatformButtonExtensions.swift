import SwiftUI

// MARK: - Cross-Platform Button Extensions

/// Cross-platform button extensions that provide consistent behavior
/// while properly handling platform differences
public extension View {

    /// Cross-platform navigation button with platform-specific behavior
    /// iOS: Shows navigation sheet; macOS: Shows sidebar toggle
    func platformNavigationSheetButton(
        action: @escaping () -> Void,
        sidebarVisibility: Binding<Bool>? = nil
    ) -> some View {
        #if os(iOS)
        return iosNavigationSheetButton(action: action, sidebarVisibility: sidebarVisibility)
        #elseif os(macOS)
        return macNavigationSheetButton(action: action, sidebarVisibility: sidebarVisibility)
        #else
        return fallbackNavigationButton(action: action)
        #endif
    }
}

// MARK: - Platform-Specific Button Components

#if os(iOS)
/// iOS-specific navigation button implementation
private func iosNavigationSheetButton(
    action: @escaping () -> Void,
    sidebarVisibility: Binding<Bool>? = nil
) -> some View {
    Button(action: action) {
        Image(systemName: "list.bullet")
    }
    .accessibilityLabel("Navigation")
    .accessibilityHint("Open navigation sheet")
    .automaticCompliance(named: "platformNavigationSheetButton")
}
#endif

#if os(macOS)
/// macOS-specific navigation button implementation
private func macNavigationSheetButton(
    action: @escaping () -> Void,
    sidebarVisibility: Binding<Bool>? = nil
) -> some View {
    Button(action: action) {
        Image(systemName: "sidebar.left")
    }
    .accessibilityLabel("Toggle Sidebar")
    .accessibilityHint("Show or hide the navigation sidebar")
    .automaticCompliance(named: "platformNavigationSheetButton")
}
#endif

/// Fallback navigation button for other platforms
private func fallbackNavigationButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "list.bullet")
    }
    .accessibilityLabel("Navigation")
    .accessibilityHint("Open navigation")
    .automaticCompliance(named: "platformNavigationSheetButton")
}
