//
//  AccessibilityCompatibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  One app launch, per-view compatibility sweep (Issue #180).
//  Implements Issue #165: Complete accessibility for all platform* methods.
//

import XCTest
@testable import SixLayerFramework

/// One launch; one test navigates to a view and runs the shared compatibility sweep (Issue #180).
@MainActor
final class AccessibilityCompatibilityUITests: XCTestCase {
    static var sharedApp: XCUIApplication?
    static var didLaunch = false

    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            if !Self.didLaunch {
                let localApp = XCUIApplication()
                localApp.launchWithOptimizations()
                XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
                Self.sharedApp = localApp
                Self.didLaunch = true
            }
            instance.app = Self.sharedApp
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
        try super.tearDownWithError()
    }

    override class func tearDown() {
        MainActor.assumeIsolated {
            sharedApp = nil
            didLaunch = false
        }
        super.tearDown()
    }

    /// Navigate to Control Test view, run compatibility sweep on that view (Issue #180).
    @MainActor
    func testControlTestView_CompatibilitySweep() throws {
        XCTAssertTrue(app.navigateBackToLaunch(timeout: 3.0), "App should be ready (launch page) before finding Control Test link")
        let link = app.findLaunchPageEntry(identifier: "test-view-Control Test")
        XCTAssertTrue(link.waitForExistence(timeout: 5.0), "Control Test link should exist on launch page")
        link.tap()
        app.runAccessibilityCompatibilitySweep()
    }

    /// Navigate to Button Test view (via Layer 4 Examples), run compatibility sweep (Issue #180).
    @MainActor
    func testButtonTestView_CompatibilitySweep() throws {
        XCTAssertTrue(app.navigateToLayerExamples(linkIdentifier: "layer4-examples-link", navigationBarTitle: "Layer 4 Examples"), "Should navigate to Layer 4 Examples")
        if app.scrollViews.firstMatch.exists {
            app.scrollViews.firstMatch.swipeDown()
        }
        var tapTarget: XCUIElement?
        if let link = app.findElement(byIdentifier: "test-view-Button Test", primaryType: .button, secondaryTypes: [.link, .cell, .staticText, .other, .any], timeout: 5.0), link.waitForExistence(timeout: 1.0) {
            tapTarget = link
        } else if app.buttons["Button Test"].waitForExistence(timeout: 2.0) {
            tapTarget = app.buttons["Button Test"]
        } else if app.staticTexts["Button Test"].waitForExistence(timeout: 1.0) {
            tapTarget = app.staticTexts["Button Test"]
        }
        guard let el = tapTarget else {
            XCTFail("Button Test link should exist on Layer 4 Examples")
            return
        }
        el.tap()
        app.runAccessibilityCompatibilitySweep()
    }
}
