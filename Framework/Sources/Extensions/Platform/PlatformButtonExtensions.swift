import SwiftUI

// MARK: - Cross-Platform Button Extensions

/// Cross-platform button extensions that provide consistent behavior
/// while properly handling platform differences
public extension View {

    /// Cross-platform navigation button with platform-specific behavior.
    ///
    /// iOS: Opens navigation sheet (hamburger-style control when ``PlatformNavigationSheetButtonVisibilityPolicy/phoneOrDetailOnly``).
    /// macOS: Sidebar toggle affordance (always shown for ``phoneOrDetailOnly``).
    ///
    /// Pair with ``platformAppNavigation_L4(columnVisibility:showingNavigationSheet:sidebar:detail:)`` by setting
    /// `action` to `{ showingNavigationSheet = true }` on iPhone/detail-only, or toggling split visibility on macOS/iPad split.
    func platformNavigationSheetButton(
        action: @escaping () -> Void,
        sidebarVisibility: Binding<Bool>? = nil,
        visibility: PlatformNavigationSheetButtonVisibilityPolicy = .always,
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        systemImage: String? = nil,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        PlatformNavigationSheetButtonHost(
            action: action,
            sidebarVisibility: sidebarVisibility,
            visibility: visibility,
            columnVisibility: columnVisibility,
            systemImage: systemImage,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }

    /// Leading toolbar slot for ``platformAppNavigation_L4`` when using ``showingNavigationSheet``.
    ///
    /// Applies ``platformToolbarWithLeadingActions`` with ``platformNavigationSheetButton(action:sidebarVisibility:visibility:columnVisibility:systemImage:accessibilityIdentifier:)``
    /// using ``PlatformNavigationSheetButtonVisibilityPolicy/phoneOrDetailOnly`` by default.
    func platformAppNavigationSheetToolbarLeading(
        showingNavigationSheet: Binding<Bool>,
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        visibility: PlatformNavigationSheetButtonVisibilityPolicy = .phoneOrDetailOnly,
        systemImage: String? = nil,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        platformToolbarWithLeadingActions {
            platformNavigationSheetButton(
                action: { showingNavigationSheet.wrappedValue = true },
                visibility: visibility,
                columnVisibility: columnVisibility,
                systemImage: systemImage,
                accessibilityIdentifier: accessibilityIdentifier
            )
        }
    }
}

// MARK: - Navigation sheet button host

private struct PlatformNavigationSheetButtonHost: View {
    let action: () -> Void
    let sidebarVisibility: Binding<Bool>?
    let visibility: PlatformNavigationSheetButtonVisibilityPolicy
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let systemImage: String?
    let accessibilityIdentifier: String?

    private var isVisible: Bool {
        PlatformNavigationSheetButtonVisibility.shouldShow(
            policy: visibility,
            deviceType: PlatformDeviceCapabilities.deviceType,
            columnVisibility: columnVisibility?.wrappedValue
        )
    }

    var body: some View {
        if isVisible {
            platformNavigationSheetButtonContent(
                action: action,
                sidebarVisibility: sidebarVisibility,
                systemImage: systemImage,
                accessibilityIdentifier: accessibilityIdentifier
            )
        }
    }
}

// MARK: - Platform-Specific Button Components

#if os(iOS)
/// iOS-specific navigation button implementation
@ViewBuilder
private func platformNavigationSheetButtonContent(
    action: @escaping () -> Void,
    sidebarVisibility: Binding<Bool>?,
    systemImage: String?,
    accessibilityIdentifier: String?
) -> some View {
    let button = Button(action: action) {
        Image(systemName: systemImage ?? "list.bullet")
    }
    .accessibilityLabel("Navigation")
    .accessibilityHint("Open navigation sheet")
    .automaticCompliance(named: "platformNavigationSheetButton")

    if let accessibilityIdentifier {
        button.accessibilityIdentifier(accessibilityIdentifier)
    } else {
        button
    }
}
#endif

#if os(macOS)
/// macOS-specific navigation button implementation
@ViewBuilder
private func platformNavigationSheetButtonContent(
    action: @escaping () -> Void,
    sidebarVisibility: Binding<Bool>?,
    systemImage: String?,
    accessibilityIdentifier: String?
) -> some View {
    let button = Button(action: action) {
        Image(systemName: systemImage ?? "sidebar.left")
    }
    .accessibilityLabel("Toggle Sidebar")
    .accessibilityHint("Show or hide the navigation sidebar")
    .automaticCompliance(named: "platformNavigationSheetButton")

    if let accessibilityIdentifier {
        button.accessibilityIdentifier(accessibilityIdentifier)
    } else {
        button
    }
}
#endif

#if !os(iOS) && !os(macOS)
@ViewBuilder
private func platformNavigationSheetButtonContent(
    action: @escaping () -> Void,
    sidebarVisibility: Binding<Bool>?,
    systemImage: String?,
    accessibilityIdentifier: String?
) -> some View {
    let button = Button(action: action) {
        Image(systemName: systemImage ?? "list.bullet")
    }
    .accessibilityLabel("Navigation")
    .accessibilityHint("Open navigation")
    .automaticCompliance(named: "platformNavigationSheetButton")

    if let accessibilityIdentifier {
        button.accessibilityIdentifier(accessibilityIdentifier)
    } else {
        button
    }
}
#endif
