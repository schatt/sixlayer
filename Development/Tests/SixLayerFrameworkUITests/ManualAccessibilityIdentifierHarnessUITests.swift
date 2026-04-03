//
//  ManualAccessibilityIdentifierHarnessUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest is the contract for manual accessibility identifiers that unit tests cannot assert reliably:
//
//  1. **ViewInspector** — `AccessibilityTestUtilities.inspectButtonAccessibilityIdentifier` often returns
//     `nil` for hosted `PlatformInteractionButton` / `platformButton` chains in `SLFiOSViewInspectorTests`.
//     A test that only does `if let id = inspect(...) { #expect(...) }` **passes without asserting** when
//     the branch is skipped, so it does not prove the identifier exists.
//
//  2. **In-process UIKit tree** — `findAllAccessibilityIdentifiersFromPlatformView` frequently yields an
//     empty list for the same hosted views in the unit-test harness, so it is not a dependable second source.
//
//  This file queries **XCUIApplication** after full launch and navigation — the same path production UI
//  tests use. The views under test live in `TestApp/TestViews/IdentifierEdgeCaseTestView.swift`.
//

import XCTest

@MainActor
final class ManualAccessibilityIdentifierHarnessUITests: XCTestCase {
    /// Fresh app per test (same lifecycle as `Layer1AccessibilityUITests`) avoids shared static app + class
    /// `tearDown` races that can destabilize the runner (exit -1) under XCTest isolation.
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.launchWithOptimizations()
            instance.app = localApp
            XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "Test app should show launch page")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    /// After UITest integration naming, explicit `platformButton(..., id:)` ids appear as
    /// `SixLayer.main.ui.<id>.Button` (see `Layer4UITests` / `ButtonTestView` comments).
    private func assertAccessibilityIdentifierContains(_ substring: String, timeout: TimeInterval = 12.0) {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        let el = app.descendants(matching: .any).matching(pred).firstMatch
        XCTAssertTrue(
            el.waitForExistence(timeout: timeout),
            "Expected an element whose accessibility identifier contains '\(substring)' (query full runtime tree)"
        )
    }

    /// Navigate: Launch → Layer 4 Examples → Identifier Edge Case; assert manual ids are queryable.
    func testManualPlatformButtonIds_queryableViaXCUITest() throws {
        XCTAssertTrue(
            app.navigateToLayerExamples(
                linkIdentifier: "layer4-examples-link",
                navigationBarTitle: "Layer 4 Examples",
                linkLabel: "Layer 4 Component Examples"
            ),
            "Should reach Layer 4 Examples from launch"
        )

        let edgeLink = app.findLaunchPageEntry(identifier: "test-view-Identifier Edge Case")
        XCTAssertTrue(edgeLink.waitForExistence(timeout: 8.0), "Identifier Edge Case link should exist")
        edgeLink.tap()

        XCTAssertTrue(
            app.navigationBars["Identifier Edge Case"].waitForExistence(timeout: 8.0),
            "Should land on Identifier Edge Case screen"
        )

        if app.scrollViews.firstMatch.exists {
            app.scrollViews.firstMatch.swipeUp()
        }

        assertAccessibilityIdentifierContains("manual-override-id")
        assertAccessibilityIdentifierContains("manual-cancel-id")
    }
}
