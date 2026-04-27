//
//  Layer5UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 5 UI tests: one test method per L5 accessibility modifier. Launch with -OpenLayer5Accessibility.
//  Each test verifies that the modifier applies a11y (automaticCompliance) to the element it wraps.
//

import XCTest
@testable import SixLayerFramework

/// Layer 5 UI tests: one test per L5 accessibility modifier so the run shows a clear pass count per function.
/// Uses launch argument -OpenLayer5Accessibility. One app launch for the suite.
@MainActor
final class Layer5UITests: XCTestCase {
    private nonisolated static let rootReadyTimeout: TimeInterval = 3.0
    private nonisolated static let quickWait: TimeInterval = 0.5
    nonisolated(unsafe) private var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append("-OpenLayer5Accessibility")
        localApp.launch()
        app = localApp
        XCTAssertTrue(localApp.wait(for: .runningForeground, timeout: Self.rootReadyTimeout),
                      "App should reach foreground")
        XCTAssertTrue(
            localApp.navigationBars["Layer 5 Examples"].waitForExistence(timeout: Self.rootReadyTimeout)
                || localApp.staticTexts["Layer 5 Examples"].waitForExistence(timeout: Self.quickWait),
            "App should open on Layer 5 Examples (launch arg)"
        )
    }

    nonisolated override func tearDownWithError() throws {
        if let runningApp = app, runningApp.state != .notRunning {
            runningApp.terminate()
            _ = runningApp.wait(for: .notRunning, timeout: 5.0)
        }
        app = nil
        try super.tearDownWithError()
    }

    @MainActor
    private func assertElementHasIdentifierFromModifier(label: String, modifierName: String) {
        let el = app.staticTexts[label].firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: Self.quickWait), "\(modifierName): element '\(label)' should exist")
        XCTAssertFalse(el.identifier.isEmpty,
                       "\(modifierName) must apply a11y to the element it wraps. '\(label)' should have identifier. Found: '\(el.identifier)'")
    }

    @MainActor
    func testL5_accessibilityEnhanced() throws {
        assertElementHasIdentifierFromModifier(label: "L5AccessibilityEnhancedContract", modifierName: "accessibilityEnhanced()")
    }

    @MainActor
    func testL5_voiceOverEnabled() throws {
        // voiceOverEnabled() uses .accessibilityElement(children: .contain); identifier is on the container.
        let el = app.otherElements["Enhanced accessibility view"].firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: Self.quickWait), "voiceOverEnabled(): container 'Enhanced accessibility view' should exist")
        XCTAssertFalse(el.identifier.isEmpty,
                       "voiceOverEnabled() must apply a11y to the view it presents. Container should have identifier. Found: '\(el.identifier)'")
    }

    @MainActor
    func testL5_keyboardNavigable() throws {
        assertElementHasIdentifierFromModifier(label: "L5KeyboardNavigableContract", modifierName: "keyboardNavigable()")
    }

    @MainActor
    func testL5_highContrastEnabled() throws {
        assertElementHasIdentifierFromModifier(label: "L5HighContrastContract", modifierName: "highContrastEnabled()")
    }
}
