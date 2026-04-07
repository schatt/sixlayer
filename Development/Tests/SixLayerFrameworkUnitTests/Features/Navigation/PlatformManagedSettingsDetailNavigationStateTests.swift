//
//  PlatformManagedSettingsDetailNavigationStateTests.swift
//  Issue #209 — sub-pane stack state (detail column / phone push depth)
//

import Testing
@testable import SixLayerFramework

private enum SubPaneID: String, Sendable {
    case data
    case cleanup
}

@Suite("PlatformManagedSettingsDetailNavigationState (#209)")
struct PlatformManagedSettingsDetailNavigationStateTests {

    @Test
    func init_empty_path() {
        let state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        #expect(state.path.isEmpty)
    }

    @Test
    func push_appends() {
        var state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        state.push(.data)
        #expect(state.path == [.data])
        state.push(.cleanup)
        #expect(state.path == [.data, .cleanup])
    }

    @Test
    func pop_removesLast() {
        var state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        state.push(.data)
        state.push(.cleanup)
        state.pop()
        #expect(state.path == [.data])
        state.pop()
        #expect(state.path.isEmpty)
    }

    @Test
    func pop_whenEmpty_noOp() {
        var state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        state.pop()
        #expect(state.path.isEmpty)
    }

    @Test
    func popToRoot_clears() {
        var state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        state.push(.data)
        state.push(.cleanup)
        state.popToRoot()
        #expect(state.path.isEmpty)
    }

    @Test
    func init_path_preservesOrder() {
        let state = PlatformManagedSettingsDetailNavigationState<SubPaneID>(path: [.data, .cleanup])
        #expect(state.path == [.data, .cleanup])
    }
}
