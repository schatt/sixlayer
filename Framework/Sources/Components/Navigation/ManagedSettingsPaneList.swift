//
//  ManagedSettingsPaneList.swift
//  SixLayerFramework
//
//  Issue #214: optional default settings sidebar from pane descriptors.
//

import SwiftUI

/// Default sidebar list for managed settings, built from ``SettingsPaneDescriptor`` rows and sections.
///
/// Use with ``View/platformManagedSettingsTopLevel_L4(state:sidebar:detail:)`` when you do not need a fully custom
/// sidebar or ``platformPresentSettings_L1``. For semantic lists and richer presentation, keep using L1 + descriptors.
public struct ManagedSettingsPaneList<ID: Hashable & Sendable>: View {
    private let grouped: [(section: String?, descriptors: [SettingsPaneDescriptor<ID>])]
    private let state: Binding<PlatformManagedSettingsTopLevelState<ID>>
    private let navigationTitle: LocalizedStringKey?
    private let onSelectionChange: ((ID?) -> Void)?

    /// - Parameters:
    ///   - descriptors: Top-level pane descriptors (duplicate IDs throw ``SettingsPaneSectionBuilderError``).
    ///   - state: Binding to ``PlatformManagedSettingsTopLevelState`` (same as the managed shell).
    ///   - navigationTitle: Title for the sidebar list; pass `nil` to omit ``View/navigationTitle(_:)-6lwfn``.
    ///   - onSelectionChange: When non-`nil`, invoked instead of mutating `state` so you can call
    ///     ``PlatformManagedSettingsFlowLogic/selectTopLevelPane(_:topLevel:detailNavigation:)`` and reset detail stacks.
    public init(
        descriptors: [SettingsPaneDescriptor<ID>],
        state: Binding<PlatformManagedSettingsTopLevelState<ID>>,
        navigationTitle: LocalizedStringKey? = "Settings",
        onSelectionChange: ((ID?) -> Void)? = nil
    ) throws {
        self.grouped = try SettingsPaneSectionBuilder.groupedBySection(descriptors)
        self.state = state
        self.navigationTitle = navigationTitle
        self.onSelectionChange = onSelectionChange
    }

    public var body: some View {
        let _ = navigationTitle
        EmptyView()
    }

    private func selectionBinding() -> Binding<ID?> {
        Binding(
            get: { state.wrappedValue.selectedTopLevel },
            set: { newValue in
                _ = (newValue, onSelectionChange)
                // TDD red stub: selection does not mutate state (issue #214).
            }
        )
    }
}

// MARK: - Unit test surface

extension ManagedSettingsPaneList {
    /// Total descriptor rows after section grouping (internal for `@testable` unit tests, issue #214).
    internal var testDescriptorRowCount: Int {
        grouped.count
    }

    /// Exposes the same selection binding the list uses (internal for `@testable` unit tests, issue #214).
    internal var testSelectionBinding: Binding<ID?> {
        selectionBinding()
    }
}
