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
        sharedApp = nil
        didLaunch = false
        super.tearDown()
    }

    /// Navigate to Control Test view, run compatibility sweep on that view (Issue #180).
    @MainActor
    func testControlTestView_CompatibilitySweep() throws {
        let link = app.findLaunchPageEntry(identifier: "test-view-Control Test")
        XCTAssertTrue(link.waitForExistence(timeout: 3.0), "Control Test link should exist")
        link.tap()
        app.runAccessibilityCompatibilitySweep()
    }

    /// Navigate to Button Test view, run compatibility sweep (Issue #180). Returns to launch first if needed.
    @MainActor
    func testButtonTestView_CompatibilitySweep() throws {
        XCTAssertTrue(app.navigateBackToLaunch(timeout: 5.0), "Should reach launch page for Button Test")
        let link = app.findLaunchPageEntry(identifier: "test-view-Button Test")
        XCTAssertTrue(link.waitForExistence(timeout: 3.0), "Button Test link should exist")
        link.tap()
        app.runAccessibilityCompatibilitySweep()
    }
}
