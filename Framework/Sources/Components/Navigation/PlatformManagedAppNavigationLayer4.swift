//
//  PlatformManagedAppNavigationLayer4.swift
//  SixLayerFramework
//
//  Issue #331: managed app navigation shell from pane descriptors.
//

import SwiftUI

extension View {
    /// Framework-owned adaptive app navigation: descriptor sidebar + detail for selection.
    ///
    /// Prefer this over opaque ``platformAppNavigation_L4(sidebar:detail:)`` when the sidebar is a
    /// labeled list that should step down to icon-rail chrome. The ViewBuilder overload remains the
    /// escape hatch for custom chrome.
    @MainActor
    @ViewBuilder
    func platformManagedAppNavigation_L4<ID: Hashable & Sendable, Detail: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        showingNavigationSheet: Binding<Bool>? = nil,
        state: Binding<PlatformAppNavigationTopLevelState<ID>>,
        descriptors: [AppNavigationPaneDescriptor<ID>],
        navigationTitle: LocalizedStringKey? = nil,
        @ViewBuilder detail: @escaping (ID?) -> Detail
    ) -> some View {
        ManagedAppNavigationShell(
            columnVisibility: columnVisibility,
            showingNavigationSheet: showingNavigationSheet,
            state: state,
            descriptors: descriptors,
            navigationTitle: navigationTitle,
            detail: detail
        )
    }
}

/// Host that builds the managed list once (throws → empty sidebar) and wires existing L4.
private struct ManagedAppNavigationShell<ID: Hashable & Sendable, Detail: View>: View {
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let showingNavigationSheet: Binding<Bool>?
    let state: Binding<PlatformAppNavigationTopLevelState<ID>>
    let descriptors: [AppNavigationPaneDescriptor<ID>]
    let navigationTitle: LocalizedStringKey?
    let detail: (ID?) -> Detail

    var body: some View {
        EmptyView()
            .platformAppNavigation_L4(
                columnVisibility: columnVisibility,
                showingNavigationSheet: showingNavigationSheet,
                sidebar: { sidebarContent },
                detail: { detail(state.wrappedValue.selectedPane) }
            )
    }

    @ViewBuilder
    private var sidebarContent: some View {
        if let list = try? ManagedAppNavigationPaneList(
            descriptors: descriptors,
            state: state,
            navigationTitle: navigationTitle
        ) {
            list
        } else {
            EmptyView()
        }
    }
}
