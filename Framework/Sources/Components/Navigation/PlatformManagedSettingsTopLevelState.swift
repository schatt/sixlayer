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
///
/// When `ID` is ``Swift/CaseIterable`` (typically a `String`-backed `enum`), use
/// ``PlatformManagedSettingsTopLevelState/init(deviceType:)`` so the pane set is **fixed at compile time**.
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

// MARK: - CaseIterable (compile-time pane set)

extension PlatformManagedSettingsTopLevelState where ID: CaseIterable {
    /// Initialize from **all** cases of `ID` in **declaration order** (e.g. `enum` cases).
    ///
    /// Use a fixed `enum` conforming to `Hashable` and ``Swift/CaseIterable`` so the pane list is
    /// **static in source** (issue #209) instead of a runtime `[ID]` array.
    public init(deviceType: DeviceType) {
        self.init(orderedTopLevelPaneIDs: Array(ID.allCases), deviceType: deviceType)
    }
}
