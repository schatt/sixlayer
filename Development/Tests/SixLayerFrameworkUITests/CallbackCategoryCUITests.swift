//
//  CallbackCategoryCUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #199: Category C UI backfill for form + collection callbacks.
//  Strict TDD: this suite is added first and should fail until TestApp host exists.
//

import XCTest

@MainActor
final class CallbackCategoryCUITests: XCTestCase {
    private enum IDs {
        static let hostTitle = "Category C Callback Coverage"
        static let formStateText = "category-c-form-state-text"
        static let formSubmitButton = "category-c-form-submit-button"
        static let formCancelButton = "category-c-form-cancel-button"
        static let selectionStateText = "category-c-selection-state-text"
        static let selectionRowSecond = "category-c-selection-row-2"
    }

    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenCategoryCCallbacks")
            localApp.launch()
            instance.app = localApp

            XCTAssertTrue(
                localApp.staticTexts[IDs.hostTitle].waitForExistence(timeout: 6.0),
                "Category C callback host should appear with -OpenCategoryCCallbacks"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    func testCategoryC_formFlow_submitThenCancel_updatesVisibleCallbackState() throws {
        let state = app.staticTexts[IDs.formStateText]
        XCTAssertTrue(state.waitForExistence(timeout: 4.0), "Form callback state label should exist")
        XCTAssertEqual(state.label, "Form callback state: none")

        let submit = app.buttons[IDs.formSubmitButton]
        XCTAssertTrue(submit.waitForExistence(timeout: 4.0), "Submit action should exist")
        submit.tap()
        XCTAssertEqual(state.label, "Form callback state: submit")

        let cancel = app.buttons[IDs.formCancelButton]
        XCTAssertTrue(cancel.waitForExistence(timeout: 4.0), "Cancel action should exist")
        cancel.tap()
        XCTAssertEqual(state.label, "Form callback state: cancel")
    }

    func testCategoryC_selectionFlow_tappingItem_updatesVisibleSelectionState() throws {
        let state = app.staticTexts[IDs.selectionStateText]
        XCTAssertTrue(state.waitForExistence(timeout: 4.0), "Selection callback state label should exist")
        XCTAssertEqual(state.label, "Selected item: none")

        let row = app.buttons[IDs.selectionRowSecond]
        XCTAssertTrue(row.waitForExistence(timeout: 5.0), "Selection row should exist")
        row.tap()

        XCTAssertEqual(state.label, "Selected item: Category C Item 2")
    }
}
