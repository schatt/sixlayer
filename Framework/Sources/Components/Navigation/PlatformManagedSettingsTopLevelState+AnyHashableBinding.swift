//
//  PlatformManagedSettingsTopLevelState+AnyHashableBinding.swift
//  SixLayerFramework
//
//  Bridge to platformSettingsContainer_L4 selectedCategory binding. Issue #209.
//

import SwiftUI

extension PlatformManagedSettingsTopLevelState {
    /// Two-way binding for ``View/platformSettingsContainer_L4(selectedCategory:sidebar:detail:)``.
    ///
    /// `set` ignores values whose underlying type does not match `ID` (e.g. wrong `AnyHashable` box).
    public static func anyHashableBinding(_ state: Binding<Self>) -> Binding<AnyHashable?> {
        // RED (TDD): disconnected from state
        Binding(
            get: { nil },
            set: { _ in }
        )
    }
}
