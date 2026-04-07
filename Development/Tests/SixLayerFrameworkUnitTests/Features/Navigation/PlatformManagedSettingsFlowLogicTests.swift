//
//  PlatformManagedSettingsFlowLogicTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for Issue #209: managed platform settings flow (routing policy).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("PlatformManagedSettingsFlowLogic (#209)")
struct PlatformManagedSettingsFlowLogicTests {

    // MARK: - recommendedInitialTopSelection

    @Test func recommendedInitialTopSelection_iPad_nonEmpty_returnsFirstPane() {
        let panes = ["general", "privacy"]
        let got = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: panes,
            deviceType: .pad
        )
        #expect(got == "general")
    }

    @Test func recommendedInitialTopSelection_macOS_nonEmpty_returnsFirstPane() {
        let panes = ["general", "privacy"]
        let got = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: panes,
            deviceType: .mac
        )
        #expect(got == "general")
    }

    @Test func recommendedInitialTopSelection_iPhone_nonEmpty_returnsNil() {
        let panes = ["general", "privacy"]
        let got = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: panes,
            deviceType: .phone
        )
        #expect(got == nil)
    }

    @Test func recommendedInitialTopSelection_iPad_empty_returnsNil() {
        let panes: [String] = []
        let got = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: panes,
            deviceType: .pad
        )
        #expect(got == nil)
    }

    // MARK: - usesSplitStyleTopLevelSettingsShell

    @Test func splitStyleTopLevel_iPad_true() {
        #expect(PlatformManagedSettingsFlowLogic.usesSplitStyleTopLevelSettingsShell(deviceType: .pad))
    }

    @Test func splitStyleTopLevel_macOS_true() {
        #expect(PlatformManagedSettingsFlowLogic.usesSplitStyleTopLevelSettingsShell(deviceType: .mac))
    }

    @Test func splitStyleTopLevel_iPhone_false() {
        #expect(!PlatformManagedSettingsFlowLogic.usesSplitStyleTopLevelSettingsShell(deviceType: .phone))
    }

    // MARK: - subPaneNavigationUsesSystemStack

    @Test func subPaneUsesSystemStack_iPhone_true() {
        #expect(PlatformManagedSettingsFlowLogic.subPaneNavigationUsesSystemStack(deviceType: .phone))
    }

    @Test func subPaneUsesSystemStack_iPad_true() {
        #expect(PlatformManagedSettingsFlowLogic.subPaneNavigationUsesSystemStack(deviceType: .pad))
    }

    @Test func subPaneUsesSystemStack_macOS_true() {
        #expect(PlatformManagedSettingsFlowLogic.subPaneNavigationUsesSystemStack(deviceType: .mac))
    }

    // MARK: - iPhoneTopLevelDetailNavigationIsPresented (#209 stack semantics)

    @Test func iPhoneTopLevelDetailNavigationIsPresented_nilBinding_returnsNil() {
        #expect(PlatformManagedSettingsFlowLogic.iPhoneTopLevelDetailNavigationIsPresented(selectedCategory: nil) == nil)
    }

    @Test func iPhoneTopLevelDetailNavigationIsPresented_selectionNil_getFalse_setFalse_noOp() {
        var value: AnyHashable? = nil
        let binding = Binding<AnyHashable?>(
            get: { value },
            set: { value = $0 }
        )
        guard let presented = PlatformManagedSettingsFlowLogic.iPhoneTopLevelDetailNavigationIsPresented(selectedCategory: binding) else {
            Issue.record("Expected binding when selectedCategory is non-nil")
            return
        }
        #expect(presented.wrappedValue == false)
        presented.wrappedValue = false
        #expect(value == nil)
    }

    @Test func iPhoneTopLevelDetailNavigationIsPresented_selectionSet_getTrue_setFalse_clears() {
        var value: AnyHashable? = AnyHashable("general")
        let binding = Binding<AnyHashable?>(
            get: { value },
            set: { value = $0 }
        )
        guard let presented = PlatformManagedSettingsFlowLogic.iPhoneTopLevelDetailNavigationIsPresented(selectedCategory: binding) else {
            Issue.record("Expected binding when selectedCategory is non-nil")
            return
        }
        #expect(presented.wrappedValue == true)
        presented.wrappedValue = false
        #expect(value == nil)
    }
}
