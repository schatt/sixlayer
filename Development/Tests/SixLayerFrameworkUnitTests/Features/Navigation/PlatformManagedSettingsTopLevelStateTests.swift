//
//  PlatformManagedSettingsTopLevelStateTests.swift
//  Issue #209 — TDD for PlatformManagedSettingsTopLevelState
//

import Testing
@testable import SixLayerFramework

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
}
