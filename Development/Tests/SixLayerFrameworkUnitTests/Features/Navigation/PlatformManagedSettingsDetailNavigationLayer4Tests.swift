//
//  PlatformManagedSettingsDetailNavigationLayer4Tests.swift
//  Issue #209 — detail NavigationStack Layer 4 smoke tests
//
//  Xcode unit-test lane only (#512). Calls BaseTestClass; not in the SwiftPM
//  PlatformManagedSettingsFlowLogicTests sources list.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

private final class DetailNavStateHolder<SubID: Hashable & Sendable>: @unchecked Sendable {
    var state: PlatformManagedSettingsDetailNavigationState<SubID>
    init(_ state: PlatformManagedSettingsDetailNavigationState<SubID>) { self.state = state }
    var binding: Binding<PlatformManagedSettingsDetailNavigationState<SubID>> {
        Binding(get: { self.state }, set: { self.state = $0 })
    }
}

private enum DetailTestSubID: String, Hashable, Sendable {
    case a
}

@Suite("PlatformManagedSettingsDetailNavigationLayer4 (#209)")
struct PlatformManagedSettingsDetailNavigationLayer4Tests {

    @Test @MainActor
    func platformManagedSettingsDetailNavigationStack_L4_buildsView() {
        let holder = DetailNavStateHolder(PlatformManagedSettingsDetailNavigationState<DetailTestSubID>())
        let view = Text("Root")
            .platformManagedSettingsDetailNavigationStack_L4(state: holder.binding) {
                Text("Inner")
            }
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_ConditionalContent")
    }
}
