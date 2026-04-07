//
//  PlatformManagedSettingsFlowLogicTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for Issue #209: managed platform settings flow (routing policy).
//

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
}
