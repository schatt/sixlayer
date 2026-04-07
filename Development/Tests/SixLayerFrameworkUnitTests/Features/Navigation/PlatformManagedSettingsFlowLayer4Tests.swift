//
//  PlatformManagedSettingsFlowLayer4Tests.swift
//  Issue #209 — managed top-level Layer 4 modifier smoke tests
//

import SwiftUI
import Testing
@testable import SixLayerFramework

private final class ManagedSettingsHolder<ID: Hashable & Sendable>: @unchecked Sendable {
    var state: PlatformManagedSettingsTopLevelState<ID>
    init(_ state: PlatformManagedSettingsTopLevelState<ID>) { self.state = state }
    var binding: Binding<PlatformManagedSettingsTopLevelState<ID>> {
        Binding(
            get: { self.state },
            set: { self.state = $0 }
        )
    }
}

@Suite("PlatformManagedSettingsFlowLayer4 (#209)")
struct PlatformManagedSettingsFlowLayer4Tests {

    /// Smoke: modifier composes with SwiftUI and typed state (full navigation wiring covered by platformSettingsContainer_L4 tests).
    @Test @MainActor
    func platformManagedSettingsTopLevel_L4_buildsView() {
        let holder = ManagedSettingsHolder(
            PlatformManagedSettingsTopLevelState<String>(
                orderedTopLevelPaneIDs: ["general"],
                deviceType: .pad
            )
        )
        let columnVisibility = Binding<NavigationSplitViewVisibility>(
            get: { .automatic },
            set: { _ in }
        )
        let view = EmptyView()
            .platformManagedSettingsTopLevel_L4(
                columnVisibility: columnVisibility,
                state: holder.binding,
                sidebar: { Text("Sidebar") },
                detail: { Text("Detail") }
            )
        _ = view
        #expect(Bool(true), "platformManagedSettingsTopLevel_L4 should produce a view")
    }
}
