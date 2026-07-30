import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

//
//  PlatformToolbarActionsLayer4Tests.swift
//  SixLayerFrameworkUnitTests (ViewInspector lane)
//
//  Issue #352 follow-up: packing overflow must use platformMenu (Menu), not only renderPlan.
//  Revived from retired tip e98c6380 — adapted to ToolbarContent / ActionItem API on next.
//

@Suite("Platform Toolbar Actions Layer 4", HostedViewTestIsolationTrait())
open class PlatformToolbarActionsLayer4Tests: BaseTestClass {

    /// Overflow bucket must surface as SwiftUI Menu via `platformMenu` (iOS/macOS).
    /// Inspects ``PlatformToolbarActionsChrome`` (toolbar content is opaque to ViewInspector).
    @Test @MainActor func testPlatformToolbarActionsChrome_overflowExposesMenuItems() async throws {
        #if canImport(ViewInspector)
        #if os(iOS) || os(macOS)
        let items = [
            PlatformToolbarActionItem(id: "keep", priority: 0, label: "Keep", action: {}),
            PlatformToolbarActionItem(id: "bury", priority: 1, label: "Bury", action: {})
        ]
        let plan = PlatformToolbarActionsPacker.renderPlan(
            for: items.map(\.descriptor),
            capacity: PlatformToolbarActionsCapacity(maxVisible: 1),
            supportsOverflowMenu: true
        )
        guard case .inlinePlusOverflowMenu(let visibleIDs, let overflowIDs) = plan else {
            Issue.record("expected inlinePlusOverflowMenu for over-capacity actions")
            return
        }
        #expect(visibleIDs == ["keep"])
        #expect(overflowIDs == ["bury"])

        let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let chrome = PlatformToolbarActionsChrome(
            visible: visibleIDs.compactMap { byID[$0] },
            overflow: overflowIDs.compactMap { byID[$0] }
        )
        let inspected = try AnyView(chrome).inspect()
        let menu = try inspected.find(ViewType.Menu.self)
        _ = try menu.find(button: "Bury")
        #endif
        #endif
    }
}
