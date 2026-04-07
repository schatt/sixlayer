//
//  PlatformManagedSettingsDetailNavigationStateTests.swift
//  Issue #209 — sub-pane stack state (detail column / phone push depth)
//

import SwiftUI
import Testing
@testable import SixLayerFramework

private enum SubPaneID: String, Sendable {
    case data
    case cleanup
}

private final class DetailNavHolder<SubID: Hashable & Sendable>: @unchecked Sendable {
    var state: PlatformManagedSettingsDetailNavigationState<SubID>
    init(_ state: PlatformManagedSettingsDetailNavigationState<SubID>) { self.state = state }
    var binding: Binding<PlatformManagedSettingsDetailNavigationState<SubID>> {
        Binding(get: { self.state }, set: { self.state = $0 })
    }
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

    // MARK: - setPath / navigationPathBinding (NavigationStack sync, #209)

    @Test
    func setPath_replacesEntirePath() {
        var state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        state.push(.data)
        state.setPath([.cleanup])
        #expect(state.path == [.cleanup])
    }

    @Test
    func navigationPathBinding_set_updatesUnderlyingState() {
        let holder = DetailNavHolder(PlatformManagedSettingsDetailNavigationState<SubPaneID>())
        let pathBinding = PlatformManagedSettingsDetailNavigationState.navigationPathBinding(holder.binding)
        pathBinding.wrappedValue = [.data, .cleanup]
        #expect(holder.state.path == [.data, .cleanup])
        pathBinding.wrappedValue = [.data]
        #expect(holder.state.path == [.data])
    }

    @Test
    func navigationPathBinding_get_reflectsPath() {
        var state = PlatformManagedSettingsDetailNavigationState<SubPaneID>()
        state.push(.data)
        let holder = DetailNavHolder(state)
        let pathBinding = PlatformManagedSettingsDetailNavigationState.navigationPathBinding(holder.binding)
        #expect(pathBinding.wrappedValue == [.data])
    }
}
