//
//  Layer6UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 6 (System) UI tests: one launch, navigate to L6 Examples → sweep → view-specific asserts.
//

import XCTest
@testable import SixLayerFramework

/// Layer 6 system example tests. Pattern: navigate → runAccessibilityCompatibilitySweep() → asserts.
@MainActor
final class Layer6UITests: XCTestCase {
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
        try super.tearDownWithError()
    }

    @MainActor
    private func navigateToLayer6Examples() throws {
        guard app.waitForReady(timeout: 5.0) else {
            XCTFail("App should be ready for testing")
            return
        }
        let link = app.findElement(byIdentifier: "layer6-examples-link", primaryType: .button, secondaryTypes: [.cell, .staticText, .other, .any])
        guard let el = link, el.waitForExistence(timeout: 3.0) else {
            XCTFail("Layer 6 examples link should exist")
            return
        }
        el.tap()
        guard app.navigationBars["Layer 6 Examples"].waitForExistence(timeout: 3.0) else {
            XCTFail("Layer 6 Examples view should load")
            return
        }
        _ = app.cells.firstMatch.waitForExistence(timeout: 3.0)
    }

    @MainActor
    func testLayer6Examples_ComplianceSweep() throws {
        try navigateToLayer6Examples()
        app.runAccessibilityCompatibilitySweep()
    }
}
