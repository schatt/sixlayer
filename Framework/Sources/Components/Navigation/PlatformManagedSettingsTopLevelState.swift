//
//  PlatformManagedSettingsTopLevelState.swift
//  SixLayerFramework
//
//  Mutable top-level settings selection coordinated with PlatformManagedSettingsFlowLogic.
//  Issue #209: managed platform settings flow.
//

import Foundation

// MARK: - PlatformManagedSettingsTopLevelState

/// Holds the selected top-level settings pane ID for binding into `platformSettingsContainer_L4` (`selectedCategory`).
///
/// Initialize with the **ordered** list of pane IDs and a ``DeviceType``; initial selection follows
/// ``PlatformManagedSettingsFlowLogic/recommendedInitialTopSelection(panes:deviceType:)``.
public struct PlatformManagedSettingsTopLevelState<ID: Hashable & Sendable>: Sendable {
    public private(set) var selectedTopLevel: ID?

    /// RED (TDD): ignores flow logic — wrong initial selection.
    public init(orderedTopLevelPaneIDs: [ID], deviceType: DeviceType) {
        self.selectedTopLevel = orderedTopLevelPaneIDs.last
    }

    /// RED: no-op
    public mutating func selectTopLevel(_ id: ID) {}

    /// RED: no-op
    public mutating func clearTopLevelSelection() {}
}
