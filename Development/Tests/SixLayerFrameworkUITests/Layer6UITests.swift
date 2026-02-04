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
        guard app.navigateToLayerExamples(linkIdentifier: "layer6-examples-link", navigationBarTitle: "Layer 6 Examples") else {
            XCTFail("Should navigate to Layer 6 Examples")
            return
        }
    }

    @MainActor
    func testLayer6Examples_ComplianceSweep() throws {
        try navigateToLayer6Examples()
        app.runAccessibilityCompatibilitySweep()
    }
}
