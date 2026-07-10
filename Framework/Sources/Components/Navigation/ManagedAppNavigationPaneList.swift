//
//  ManagedAppNavigationPaneList.swift
//  SixLayerFramework
//
//  Issue #331: framework-owned adaptive app-nav sidebar from descriptors.
//

import SwiftUI

/// Default sidebar list for managed app navigation, built from ``AppNavigationPaneDescriptor`` rows.
///
/// Steps label ↔ denser label ↔ icon-only from ``EnvironmentValues/navigationSidebarRenderingProfile``.
/// Icon-only rows keep accessibility labels from ``AppNavigationPaneDescriptor/titleKey``.
public struct ManagedAppNavigationPaneList<ID: Hashable & Sendable>: View {
    @Environment(\.navigationSidebarRenderingProfile) private var renderingProfile

    private let grouped: [(section: String?, descriptors: [AppNavigationPaneDescriptor<ID>])]
    private let state: Binding<PlatformAppNavigationTopLevelState<ID>>
    private let navigationTitle: LocalizedStringKey?
    private let onSelectionChange: ((ID?) -> Void)?

    public init(
        descriptors: [AppNavigationPaneDescriptor<ID>],
        state: Binding<PlatformAppNavigationTopLevelState<ID>>,
        navigationTitle: LocalizedStringKey? = nil,
        onSelectionChange: ((ID?) -> Void)? = nil
    ) throws {
        self.grouped = try AppNavigationPaneSectionBuilder.groupedBySection(descriptors)
        self.state = state
        self.navigationTitle = navigationTitle
        self.onSelectionChange = onSelectionChange
    }

    public var body: some View {
        let list = List(selection: selectionBinding()) {
            ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                section(group)
            }
        }

        if let navigationTitle {
            list.navigationTitle(navigationTitle)
        } else {
            list
        }
    }

    @ViewBuilder
    private func section(
        _ group: (section: String?, descriptors: [AppNavigationPaneDescriptor<ID>])
    ) -> some View {
        if let sectionTitle = group.section {
            Section {
                paneRows(group.descriptors)
            } header: {
                Text(LocalizedStringKey(sectionTitle))
            }
        } else {
            Section {
                paneRows(group.descriptors)
            }
        }
    }

    @ViewBuilder
    private func paneRows(_ descriptors: [AppNavigationPaneDescriptor<ID>]) -> some View {
        ForEach(descriptors, id: \.id) { pane in
            paneRow(pane)
                .tag(Optional(pane.id))
        }
    }

    @ViewBuilder
    private func paneRow(_ pane: AppNavigationPaneDescriptor<ID>) -> some View {
        switch AppNavigationSidebarRowPresentation.forProfile(renderingProfile) {
        case .iconOnly:
            Image(systemName: pane.systemImage)
                .accessibilityLabel(
                    Text(LocalizedStringKey(AppNavigationSidebarRowAccessibility.iconOnlyLabel(for: pane)))
                )
        case .compactLabeled:
            Label {
                Text(LocalizedStringKey(pane.titleKey))
                    .font(.subheadline)
            } icon: {
                Image(systemName: pane.systemImage)
            }
        case .labeled:
            Label {
                Text(LocalizedStringKey(pane.titleKey))
            } icon: {
                Image(systemName: pane.systemImage)
            }
        }
    }

    @MainActor
    private func selectionBinding() -> Binding<ID?> {
        Binding(
            get: { state.wrappedValue.selectedPane },
            set: { newValue in
                if let onSelectionChange {
                    onSelectionChange(newValue)
                } else {
                    var next = state.wrappedValue
                    if let id = newValue {
                        next.selectPane(id)
                    } else {
                        next.clearSelection()
                    }
                    state.wrappedValue = next
                }
            }
        )
    }
}

// MARK: - Unit test surface

extension ManagedAppNavigationPaneList {
    internal var testDescriptorRowCount: Int {
        grouped.flatMap(\.descriptors).count
    }

    @MainActor
    internal var testSelectionBinding: Binding<ID?> {
        selectionBinding()
    }

    internal var testRenderingProfile: NavigationSidebarProfile {
        renderingProfile
    }

    internal func testRowPresentation() -> AppNavigationSidebarRowPresentation {
        AppNavigationSidebarRowPresentation.forProfile(renderingProfile)
    }
}
