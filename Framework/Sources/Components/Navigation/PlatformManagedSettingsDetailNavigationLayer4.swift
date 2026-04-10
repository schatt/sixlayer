//
//  PlatformManagedSettingsDetailNavigationLayer4.swift
//  SixLayerFramework
//
//  Detail-column / sub-pane NavigationStack on top of PlatformManagedSettingsDetailNavigationState. Issue #209.
//

import SwiftUI

extension View {
    /// Wraps content in a ``SwiftUI/NavigationStack`` driven by ``PlatformManagedSettingsDetailNavigationState``
    /// so sub-pane depth uses **system stack** semantics (push, back) inside the settings detail column or
    /// full-screen stack on phone.
    ///
    /// Attach ``SwiftUI/View/navigationDestination(for:destination:)`` (and optional nested destinations) on
    /// **root** content for each `SubID` you push onto the path.
    ///
    /// On platforms/OS versions without `NavigationStack`, returns `content` only (path updates still apply to state).
    @MainActor
    @ViewBuilder
    func platformManagedSettingsDetailNavigationStack_L4<SubID: Hashable & Sendable, Content: View>(
        state: Binding<PlatformManagedSettingsDetailNavigationState<SubID>>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            NavigationStack(
                path: PlatformManagedSettingsDetailNavigationState.navigationPathBinding(state),
                root: content
            )
        } else {
            content()
        }
    }
}
