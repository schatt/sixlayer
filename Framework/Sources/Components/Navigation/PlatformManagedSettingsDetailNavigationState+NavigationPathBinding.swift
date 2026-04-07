//
//  PlatformManagedSettingsDetailNavigationState+NavigationPathBinding.swift
//  SixLayerFramework
//
//  Bridge to SwiftUI NavigationStack(path:). Issue #209.
//

import SwiftUI

extension PlatformManagedSettingsDetailNavigationState {
    /// Two-way binding for ``SwiftUI/NavigationStack`` `path` when `SubID` is the path element type.
    ///
    /// Use: `NavigationStack(path: PlatformManagedSettingsDetailNavigationState.navigationPathBinding($detailNav)) { ... }`
    public static func navigationPathBinding(_ state: Binding<Self>) -> Binding<[SubID]> {
        Binding(
            get: { state.wrappedValue.path },
            set: { newPath in
                var s = state.wrappedValue
                s.setPath(newPath)
                state.wrappedValue = s
            }
        )
    }
}
