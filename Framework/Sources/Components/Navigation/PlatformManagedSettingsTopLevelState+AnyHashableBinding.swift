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
        Binding(
            get: { state.wrappedValue.selectedTopLevel.map { AnyHashable($0) } },
            set: { newValue in
                if let newValue {
                    guard let id = newValue.base as? ID else { return }
                    var s = state.wrappedValue
                    s.selectTopLevel(id)
                    state.wrappedValue = s
                } else {
                    var s = state.wrappedValue
                    s.clearTopLevelSelection()
                    state.wrappedValue = s
                }
            }
        )
    }
}
