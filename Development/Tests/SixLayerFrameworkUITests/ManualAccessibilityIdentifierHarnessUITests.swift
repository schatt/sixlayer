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
            localApp.configureForFastTesting()
            // Deep-link full Layer 4 component list (Identifier Edge Case lives here). Avoids launch-page scroll / combined-a11y flakiness.
            localApp.launchArguments.append("-OpenLayer4ComponentExamples")
            localApp.launch()
            instance.app = localApp
            // Large-title layouts may not expose "Layer 4 Examples" on NavigationBar immediately; section title is stable.
            let onLayer4 = localApp.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 5.0)
                || localApp.staticTexts["Layer 4 Examples"].waitForExistence(timeout: 2.0)
                || localApp.staticTexts["Component test views"].waitForExistence(timeout: 8.0)
            XCTAssertTrue(onLayer4, "Test app should open Layer 4 Examples (-OpenLayer4ComponentExamples)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    /// `Layer4ExamplesView` can host multiple `ScrollView`s (e.g. navigation chrome). Prefer the outer list host like `Layer4UITests.primaryScrollHost()`.
    private func swipeLayer4ExamplesListUp() {
        let svs = app.scrollViews
        let n = svs.count
        guard n > 0 else {
            app.swipeUp()
            return
        }
        let idx = n > 1 ? n - 1 : 0
        svs.element(boundBy: idx).swipeUp()
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

    /// SetUp opens Layer 4 Examples via `-OpenLayer4ComponentExamples`. Navigate: Identifier Edge Case → assert manual ids queryable.
    func testManualPlatformButtonIds_queryableViaXCUITest() throws {
        let edgeId = "test-view-Identifier Edge Case"
        let idQuery = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", edgeId)).firstMatch
        let labelQuery = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Identifier Edge Case")).firstMatch

        func resolveEdgeRow() -> XCUIElement {
            if idQuery.waitForExistence(timeout: 0.4), idQuery.isHittable { return idQuery }
            if labelQuery.waitForExistence(timeout: 0.4), labelQuery.isHittable { return labelQuery }
            let fallback = app.findLaunchPageEntry(identifier: edgeId)
            if fallback.waitForExistence(timeout: 0.3), fallback.isHittable { return fallback }
            return app.links["Identifier Edge Case"].firstMatch
        }

        var edgeLink = resolveEdgeRow()
        for _ in 0..<20 {
            if edgeLink.waitForExistence(timeout: 0.4), edgeLink.isHittable { break }
            swipeLayer4ExamplesListUp()
            edgeLink = resolveEdgeRow()
        }
        XCTAssertTrue(edgeLink.waitForExistence(timeout: 6.0) && edgeLink.isHittable, "Identifier Edge Case link should exist")
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
