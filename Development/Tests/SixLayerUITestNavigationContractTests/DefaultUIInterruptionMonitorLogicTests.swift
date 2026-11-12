//
//  DefaultUIInterruptionMonitorLogicTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Default UI interruption monitor policy (#584).
//

import XCTest
@testable import SixLayerTestKit

final class DefaultUIInterruptionMonitorLogicTests: XCTestCase {

    func testNilAlertLabel_isNotHandled_evenIfButtonsExist() {
        // Interrupting process quit → unreadable label → not handled (must not fail the test).
        var tapped: String?
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabel: nil,
            buttonExists: { _ in true },
            tapButton: { tapped = $0 }
        )
        XCTAssertFalse(handled)
        XCTAssertNil(tapped)
    }

    func testFailureResult_isNotHandled() {
        var tapped: String?
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabelResult: .failure(NSError(domain: "test", code: 1)),
            buttonExists: { _ in true },
            tapButton: { tapped = $0 }
        )
        XCTAssertFalse(handled)
        XCTAssertNil(tapped)
    }

    func testBluetoothAlert_tapsOKWhenPresent() {
        var tapped: String?
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabel: "Turn On Bluetooth",
            buttonExists: { $0 == "OK" },
            tapButton: { tapped = $0 }
        )
        XCTAssertTrue(handled)
        XCTAssertEqual(tapped, "OK")
    }

    func testUnrelatedAlert_isNotHandled() {
        var tapped: String?
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabel: "Save changes?",
            buttonExists: { _ in true },
            tapButton: { tapped = $0 }
        )
        XCTAssertFalse(handled)
        XCTAssertNil(tapped)
    }

    func testCPUAlert_prefersFirstExistingDismissButton() {
        var tapped: String?
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabel: "High CPU Usage",
            buttonExists: { $0 == "Cancel" || $0 == "Don't Allow" },
            tapButton: { tapped = $0 }
        )
        XCTAssertTrue(handled)
        XCTAssertEqual(tapped, "Cancel")
    }

    func testActivityMonitorKeyword_withNoButtons_returnsFalse() {
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabel: "Activity Monitor",
            buttonExists: { _ in false },
            tapButton: { _ in XCTFail("should not tap") }
        )
        XCTAssertFalse(handled)
    }

    func testSuccessResult_usesLabelForDecision() {
        var tapped: String?
        let handled = DefaultUIInterruptionMonitorLogic.handle(
            alertLabelResult: .success("Bluetooth pairing request"),
            buttonExists: { $0 == "Don't Allow" },
            tapButton: { tapped = $0 }
        )
        XCTAssertTrue(handled)
        XCTAssertEqual(tapped, "Don't Allow")
    }
}
