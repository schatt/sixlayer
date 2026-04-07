//
//  PlatformManagedSettingsTopLevelStateTests.swift
//  Issue #209 — TDD for PlatformManagedSettingsTopLevelState
//

import SwiftUI
import Testing
@testable import SixLayerFramework

// MARK: - Binding test holder

private final class TopLevelStateHolder<ID: Hashable & Sendable>: @unchecked Sendable {
    var state: PlatformManagedSettingsTopLevelState<ID>
    init(_ state: PlatformManagedSettingsTopLevelState<ID>) { self.state = state }
    var binding: Binding<PlatformManagedSettingsTopLevelState<ID>> {
        Binding(
            get: { self.state },
            set: { self.state = $0 }
        )
    }
}

@Suite("PlatformManagedSettingsTopLevelState (#209)")
struct PlatformManagedSettingsTopLevelStateTests {

    @Test
    func init_iPad_nonEmpty_selectsFirstPane() {
        let state = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: ["general", "privacy"],
            deviceType: .pad
        )
        #expect(state.selectedTopLevel == "general")
    }

    @Test
    func init_macOS_nonEmpty_selectsFirstPane() {
        let state = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: ["general", "privacy"],
            deviceType: .mac
        )
        #expect(state.selectedTopLevel == "general")
    }

    @Test
    func init_iPhone_nonEmpty_startsWithNilSelection() {
        let state = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: ["general", "privacy"],
            deviceType: .phone
        )
        #expect(state.selectedTopLevel == nil)
    }

    @Test
    func init_emptyPaneList_startsWithNilSelection() {
        let state = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: [],
            deviceType: .pad
        )
        #expect(state.selectedTopLevel == nil)
    }

    @Test
    func selectTopLevel_updatesSelection() {
        var state = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: ["a", "b"],
            deviceType: .pad
        )
        state.selectTopLevel("b")
        #expect(state.selectedTopLevel == "b")
    }

    @Test
    func clearTopLevelSelection_clearsSelection() {
        var state = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: ["only"],
            deviceType: .pad
        )
        #expect(state.selectedTopLevel == "only")
        state.clearTopLevelSelection()
        #expect(state.selectedTopLevel == nil)
    }

    // MARK: - anyHashableBinding (platformSettingsContainer_L4)

    @Test
    func anyHashableBinding_get_reflectsSelection_iPad() {
        let holder = TopLevelStateHolder(
            PlatformManagedSettingsTopLevelState<String>(
                orderedTopLevelPaneIDs: ["a", "b"],
                deviceType: .pad
            )
        )
        let anyBinding = PlatformManagedSettingsTopLevelState.anyHashableBinding(holder.binding)
        #expect(anyBinding.wrappedValue == AnyHashable("a"))
    }

    @Test
    func anyHashableBinding_set_updatesUnderlyingSelection() {
        let holder = TopLevelStateHolder(
            PlatformManagedSettingsTopLevelState<String>(
                orderedTopLevelPaneIDs: ["a", "b"],
                deviceType: .pad
            )
        )
        var anyBinding = PlatformManagedSettingsTopLevelState.anyHashableBinding(holder.binding)
        anyBinding.wrappedValue = AnyHashable("b")
        #expect(holder.state.selectedTopLevel == "b")
    }

    @Test
    func anyHashableBinding_set_nil_clearsSelection() {
        let holder = TopLevelStateHolder(
            PlatformManagedSettingsTopLevelState<String>(
                orderedTopLevelPaneIDs: ["only"],
                deviceType: .pad
            )
        )
        var anyBinding = PlatformManagedSettingsTopLevelState.anyHashableBinding(holder.binding)
        anyBinding.wrappedValue = nil
        #expect(holder.state.selectedTopLevel == nil)
    }

    @Test
    func anyHashableBinding_set_mismatchedBaseType_doesNotChangeSelection() {
        let holder = TopLevelStateHolder(
            PlatformManagedSettingsTopLevelState<String>(
                orderedTopLevelPaneIDs: ["a", "b"],
                deviceType: .pad
            )
        )
        var anyBinding = PlatformManagedSettingsTopLevelState.anyHashableBinding(holder.binding)
        anyBinding.wrappedValue = AnyHashable(42)
        #expect(holder.state.selectedTopLevel == "a")
    }
}
