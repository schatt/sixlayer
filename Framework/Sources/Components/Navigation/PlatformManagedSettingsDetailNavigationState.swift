//
//  PlatformManagedSettingsDetailNavigationState.swift
//  SixLayerFramework
//
//  Mutable sub-pane stack for hierarchical settings under a top-level pane. Issue #209.
//

import Foundation

// MARK: - PlatformManagedSettingsDetailNavigationState

/// Holds a **stack** of sub-route identifiers for hierarchical settings **inside** a top-level pane.
///
/// Pair with SwiftUI ``SwiftUI/NavigationStack`` using
/// ``PlatformManagedSettingsDetailNavigationState/navigationPathBinding(_:)`` for `path`, or build a
/// `Binding<[SubID]>` yourself. Call ``popToRoot()`` when the user switches top-level categories so
/// sub-panes do not leak across panes.
///
/// Top-level selection remains ``PlatformManagedSettingsTopLevelState``; this type models **depth**
/// within the detail column / pushed stack on phone.
public struct PlatformManagedSettingsDetailNavigationState<SubID: Hashable & Sendable>: Sendable {
    public private(set) var path: [SubID]

    public init() {
        self.path = []
    }

    public init(path: [SubID]) {
        self.path = path
    }

    public mutating func push(_ id: SubID) {
        path.append(id)
    }

    /// Removes the last pushed sub-pane, if any (system back equivalent).
    public mutating func pop() {
        _ = path.popLast()
    }

    /// Clears the sub-pane stack (e.g. when switching top-level settings categories).
    public mutating func popToRoot() {
        path.removeAll()
    }

    /// Replaces the path (used when syncing from SwiftUI ``NavigationStack`` / system back).
    public mutating func setPath(_ newPath: [SubID]) {
        path = newPath
    }
}
