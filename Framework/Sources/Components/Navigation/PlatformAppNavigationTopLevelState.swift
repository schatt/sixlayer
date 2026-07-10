//
//  PlatformAppNavigationTopLevelState.swift
//  SixLayerFramework
//
//  Issue #331: top-level selection for framework-owned app navigation sidebars.
//

import Foundation

/// Holds the selected top-level app-navigation pane ID for managed app-nav shells (#331).
public struct PlatformAppNavigationTopLevelState<ID: Hashable & Sendable>: Sendable {
    public private(set) var selectedPane: ID?

    public init(orderedPaneIDs: [ID], deviceType: DeviceType) {
        self.selectedPane = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: orderedPaneIDs,
            deviceType: deviceType
        )
    }

    public mutating func selectPane(_ id: ID) {
        selectedPane = id
    }

    public mutating func clearSelection() {
        selectedPane = nil
    }
}

extension PlatformAppNavigationTopLevelState where ID: CaseIterable {
    /// Initialize from all cases of `ID` in declaration order.
    public init(deviceType: DeviceType) {
        self.init(orderedPaneIDs: Array(ID.allCases), deviceType: deviceType)
    }
}
