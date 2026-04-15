//
//  PlatformManagedSettingsFlowLogicTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for Issue #209: managed platform settings flow (routing policy).
//  Issue #211: exhaustive DeviceType shell policy matrix (split / initial selection / sub-pane stack).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

// MARK: - Shell policy matrix (#211)

/// Expected routing policy per ``DeviceType`` for managed settings shell helpers.
/// Keep in sync with ``PlatformManagedSettingsFlowLogic``; every ``DeviceType`` case must appear here.
private enum DeviceTypeSettingsShellPolicyMatrix {
    struct Expectation: Equatable, Sendable {
        /// When the ordered pane list is non-empty, whether ``recommendedInitialTopSelection`` returns the first pane (`true`) or `nil` (`false`).
        var selectsFirstPaneWhenPanesNonEmpty: Bool
        var usesSplitStyleTopLevelShell: Bool
        var subPaneUsesSystemStack: Bool
        var topLevelShellPolicy: PlatformManagedSettingsTopLevelShellPolicy
    }

    static let expectationsByDevice: [DeviceType: Expectation] = [
        .phone: .init(
            selectsFirstPaneWhenPanesNonEmpty: false,
            usesSplitStyleTopLevelShell: false,
            subPaneUsesSystemStack: true,
            topLevelShellPolicy: .stackWithSelectionPush
        ),
        .pad: .init(
            selectsFirstPaneWhenPanesNonEmpty: true,
            usesSplitStyleTopLevelShell: true,
            subPaneUsesSystemStack: true,
            topLevelShellPolicy: .splitSidebarDetail
        ),
        .mac: .init(
            selectsFirstPaneWhenPanesNonEmpty: true,
            usesSplitStyleTopLevelShell: true,
            subPaneUsesSystemStack: true,
            topLevelShellPolicy: .splitSidebarDetail
        ),
        .tv: .init(
            selectsFirstPaneWhenPanesNonEmpty: false,
            usesSplitStyleTopLevelShell: false,
            subPaneUsesSystemStack: false,
            topLevelShellPolicy: .unsupportedSidebarFallback
        ),
        .watch: .init(
            selectsFirstPaneWhenPanesNonEmpty: false,
            usesSplitStyleTopLevelShell: false,
            subPaneUsesSystemStack: true,
            topLevelShellPolicy: .unsupportedSidebarFallback
        ),
        .car: .init(
            selectsFirstPaneWhenPanesNonEmpty: false,
            usesSplitStyleTopLevelShell: false,
            subPaneUsesSystemStack: false,
            topLevelShellPolicy: .stackWithSelectionPush
        ),
        .vision: .init(
            selectsFirstPaneWhenPanesNonEmpty: false,
            usesSplitStyleTopLevelShell: false,
            subPaneUsesSystemStack: false,
            topLevelShellPolicy: .unsupportedSidebarFallback
        ),
    ]
}

private func assertShellPolicyMatrixCoversAllDeviceTypes() {
    let expectedKeys = Set(DeviceType.allCases)
    let actualKeys = Set(DeviceTypeSettingsShellPolicyMatrix.expectationsByDevice.keys)
    #expect(
        actualKeys == expectedKeys,
        "Shell policy matrix must include every DeviceType case (missing or extra: \(expectedKeys.symmetricDifference(actualKeys)))"
    )
}

@Suite("PlatformManagedSettingsFlowLogic (#209)")
struct PlatformManagedSettingsFlowLogicTests {

    // MARK: - recommendedInitialTopSelection (edge cases; non-empty paths covered by #211 matrix)

    @Test func recommendedInitialTopSelection_iPad_empty_returnsNil() {
        let panes: [String] = []
        let got = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
            panes: panes,
            deviceType: .pad
        )
        #expect(got == nil)
    }

    // MARK: - DeviceType shell policy matrix (#211)

    @Test func shellPolicyMatrix_coversEveryDeviceType() {
        assertShellPolicyMatrixCoversAllDeviceTypes()
    }

    @Test func shellPolicyMatrix_matchesPlatformManagedSettingsFlowLogic() {
        assertShellPolicyMatrixCoversAllDeviceTypes()
        let panes = ["general", "privacy"]
        for (device, expected) in DeviceTypeSettingsShellPolicyMatrix.expectationsByDevice {
            let initial = PlatformManagedSettingsFlowLogic.recommendedInitialTopSelection(
                panes: panes,
                deviceType: device
            )
            if expected.selectsFirstPaneWhenPanesNonEmpty {
                #expect(initial == "general")
            } else {
                #expect(initial == nil)
            }
            #expect(
                PlatformManagedSettingsFlowLogic.usesSplitStyleTopLevelSettingsShell(deviceType: device)
                    == expected.usesSplitStyleTopLevelShell
            )
            #expect(
                PlatformManagedSettingsFlowLogic.subPaneNavigationUsesSystemStack(deviceType: device)
                    == expected.subPaneUsesSystemStack
            )
            #expect(
                PlatformManagedSettingsFlowLogic.topLevelSettingsShellPolicy(deviceType: device)
                    == expected.topLevelShellPolicy
            )
        }
    }

    // MARK: - iPhoneTopLevelDetailNavigationIsPresented (#209 stack semantics)

    @Test @MainActor func iPhoneTopLevelDetailNavigationIsPresented_nilBinding_returnsNil() {
        #expect(PlatformManagedSettingsFlowLogic.iPhoneTopLevelDetailNavigationIsPresented(selectedCategory: nil) == nil)
    }

    @Test @MainActor func iPhoneTopLevelDetailNavigationIsPresented_selectionNil_getFalse_setFalse_noOp() {
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

    @Test @MainActor func iPhoneTopLevelDetailNavigationIsPresented_selectionSet_getTrue_setFalse_clears() {
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

    // MARK: - selectTopLevelPane (top-level + detail coordination, #209)

    private enum CoordSubPane: Hashable, Sendable {
        case deep
    }

    @Test func selectTopLevelPane_updatesTopAndClearsDetailPath() {
        var top = PlatformManagedSettingsTopLevelState<String>(
            orderedTopLevelPaneIDs: ["a", "b"],
            deviceType: .pad
        )
        var detail = PlatformManagedSettingsDetailNavigationState<CoordSubPane>()
        detail.push(.deep)
        PlatformManagedSettingsFlowLogic.selectTopLevelPane(
            "b",
            topLevel: &top,
            detailNavigation: &detail
        )
        #expect(top.selectedTopLevel == "b")
        #expect(detail.path.isEmpty)
    }
}
