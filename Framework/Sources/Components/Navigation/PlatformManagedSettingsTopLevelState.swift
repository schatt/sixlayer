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

    public init(orderedTopLevelPaneIDs: [ID], deviceType: DeviceType) {
        self.selectedTopLevel = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: orderedTopLevelPaneIDs,
            deviceType: deviceType
        )
    }

    public mutating func selectTopLevel(_ id: ID) {
        selectedTopLevel = id
    }

    public mutating func clearTopLevelSelection() {
        selectedTopLevel = nil
    }
}
