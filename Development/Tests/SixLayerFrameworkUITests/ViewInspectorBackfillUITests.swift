//
//  ViewInspectorBackfillUITests.swift
//  SixLayerFrameworkUITests
//
//  UI tests for behaviors ViewInspector cannot assert on iOS (issue #178).
//  Covers identifier edge case (manual ID) and IntelligentDetailView content.
//

import XCTest
@testable import SixLayerFramework

@MainActor
final class ViewInspectorBackfillUITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false

        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.launchWithOptimizations()
            instance.app = localApp
            XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    /// UI test for identifier edge case: manual .accessibilityIdentifier is findable (covers testManualIDOverride-style behavior).
    @MainActor
    func testIdentifierEdgeCase_ManualOverrideIdFindable() throws {
        let entryButton = app.findLaunchPageEntry(identifier: "test-view-Identifier Edge Case")
        XCTAssertTrue(entryButton.waitForExistenceFast(timeout: 3.0), "Identifier Edge Case entry should exist")
        entryButton.tap()

        // Framework generates namespaced identifiers (e.g. SixLayer.main.ui.manual-override-id.Button)
        let manualSubmitId = "SixLayer.main.ui.manual-override-id.Button"
        let manualSubmit = app.findElement(byIdentifier: manualSubmitId, primaryType: .button, secondaryTypes: [.other, .any])
        XCTAssertNotNil(manualSubmit, "Manual override identifier '\(manualSubmitId)' should be findable by XCUIElement")

        let manualCancelId = "SixLayer.main.ui.manual-cancel-id.Button"
        let manualCancel = app.findElement(byIdentifier: manualCancelId, primaryType: .button, secondaryTypes: [.other, .any])
        XCTAssertNotNil(manualCancel, "Manual override identifier '\(manualCancelId)' should be findable by XCUIElement")
    }

    /// UI test for IntelligentDetailView content: title and description are visible (covers view hierarchy / no text elements VI failures).
    @MainActor
    func testDetailView_ContentVisible() throws {
        let entryButton = app.findLaunchPageEntry(identifier: "test-view-Detail View Test")
        XCTAssertTrue(entryButton.waitForExistenceFast(timeout: 3.0), "Detail View Test entry should exist")
        entryButton.tap()

        let titleText = app.staticTexts["Detail Title"]
        XCTAssertTrue(titleText.waitForExistenceFast(timeout: 3.0), "Detail view should display title 'Detail Title'")

        let subtitleText = app.staticTexts["Detail subtitle and content for UI test to find."]
        XCTAssertTrue(subtitleText.waitForExistenceFast(timeout: 2.0), "Detail view should display description text")
    }
}
