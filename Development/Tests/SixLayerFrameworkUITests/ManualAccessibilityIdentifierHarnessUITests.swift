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
//  This file queries **XCUIApplication** after full launch — the same path production UI tests use.
//  The views under test live in `TestApp/TestViews/IdentifierEdgeCaseTestView.swift`.
//

import XCTest

@MainActor
final class ManualAccessibilityIdentifierHarnessUITests: SixLayerUITestCase {
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
            localApp.launchArguments.append("-OpenLayer4IdentifierEdgeCase")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(
                localApp.waitForHostRootIdentifier("identifier-edge-case-host-root"),
                "Test app should open Identifier Edge Case (-OpenLayer4IdentifierEdgeCase)"
            )
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
    private func assertAccessibilityIdentifierContains(_ substring: String, timeout: TimeInterval = 3.0) {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        let el = app.descendants(matching: .any).matching(pred).firstMatch
        XCTAssertTrue(
            el.waitForExistence(timeout: timeout),
            "Expected an element whose accessibility identifier contains '\(substring)'"
        )
    }

    /// Opens directly on Identifier Edge Case via `-OpenLayer4IdentifierEdgeCase`; assert manual ids queryable.
    func testManualPlatformButtonIds_queryableViaXCUITest() throws {
        assertAccessibilityIdentifierContains("manual-override-id")
        assertAccessibilityIdentifierContains("manual-cancel-id")
    }
}
