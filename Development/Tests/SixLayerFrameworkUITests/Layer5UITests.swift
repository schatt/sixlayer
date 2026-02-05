//
//  Layer5UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 5 (Optimization) UI tests: one launch, navigate to L5 Examples → sweep → view-specific asserts.
//

import XCTest
@testable import SixLayerFramework

/// Layer 5 optimization example tests. Pattern: navigate → runAccessibilityCompatibilitySweep() → asserts.
@MainActor
final class Layer5UITests: XCTestCase {
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
    private func navigateToLayer5Examples() throws {
        guard app.navigateToLayerExamples(linkIdentifier: "layer5-examples-link", navigationBarTitle: "Layer 5 Examples") else {
            XCTFail("Should navigate to Layer 5 Examples")
            return
        }
    }

    @MainActor
    func testLayer5Examples_ComplianceSweep() throws {
        try navigateToLayer5Examples()
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED
    }
}
