//
//  PlatformManagedSettingsFlowLayer4.swift
//  SixLayerFramework
//
//  Managed settings top-level flow on top of platformSettingsContainer_L4. Issue #209.
//

import SwiftUI

extension View {
    /// Managed settings shell: wires ``PlatformManagedSettingsTopLevelState`` into `selectedCategory` for
    /// ``platformSettingsContainer_L4``.
    ///
    /// - Parameters:
    ///   - columnVisibility: Optional binding for split column visibility (iPad / macOS).
    ///   - state: Binding to ``PlatformManagedSettingsTopLevelState`` (typically `@State` or held store).
    ///   - sidebar: Top-level category list (or equivalent).
    ///   - detail: Content for the selected top-level pane.
    @MainActor
    @ViewBuilder
    func platformManagedSettingsTopLevel_L4<ID: Hashable & Sendable, Sidebar: View, Detail: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        state: Binding<PlatformManagedSettingsTopLevelState<ID>>,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder detail: @escaping () -> Detail
    ) -> some View {
        self.platformSettingsContainer_L4(
            columnVisibility: columnVisibility,
            selectedCategory: PlatformManagedSettingsTopLevelState.anyHashableBinding(state),
            sidebar: sidebar,
            detail: detail
        )
    }
}
