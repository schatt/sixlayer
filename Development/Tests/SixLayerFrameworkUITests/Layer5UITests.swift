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
    /// Shared across test instances (Xcode creates one instance per test method).
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    /// One app launch for the suite; all 4 test methods reuse the same launch.
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            guard Self.sharedApp == nil else { return }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer5Accessibility")
            localApp.launch()
            Self.sharedApp = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 5 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 5 Examples (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    @MainActor
    private func assertElementHasIdentifierFromModifier(label: String, modifierName: String) {
        let el = app.staticTexts[label].firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: 2.0), "\(modifierName): element '\(label)' should exist")
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
        XCTAssertTrue(el.waitForExistence(timeout: 2.0), "voiceOverEnabled(): container 'Enhanced accessibility view' should exist")
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
