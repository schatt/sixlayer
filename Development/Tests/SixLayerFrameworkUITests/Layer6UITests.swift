//
//  Layer6UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 6 (System) UI tests: launch with -OpenLayer6Examples so the app opens
//  directly to the Cross-Platform Optimizations section. Asserts that the screen
//  presents the actual Layer 6 optimization APIs by name and that demo controls meet a11y.
//

import XCTest
@testable import SixLayerFramework

/// Layer 6 UI tests: verify the Layer 6 examples screen shows the real Layer 6 functions
/// (platformSpecificOptimizations, performanceOptimizations, uiPatternOptimizations) and
/// that the demo controls are accessible. Uses launch argument -OpenLayer6Examples.
@MainActor
final class Layer6UITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer6Examples")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 6 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 6 Examples (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
        try super.tearDownWithError()
    }

    private static let expectedSectionTitle = "Cross-Platform Optimizations"

    /// Layer 6 function names as shown in the example card descriptions (actual API names).
    private static let layer6FunctionDescriptions: [String] = [
        "platformNavigationStackEnhancements_L6",
        "platformSpecificOptimizations(for:)",
        "performanceOptimizations(using:)",
        "uiPatternOptimizations(using:)",
        "All optimization types combined",
    ]

    /// Buttons inside each demo card (platformButton, not Layer 6); used for a11y contract checks.
    private static let expectedButtons: [(id: String, label: String)] = [
        ("platform-specific-optimized", "Optimized Button"),
        ("performance-optimized", "Optimized Button"),
        ("ui-pattern-optimized", "Optimized Button"),
        ("fully-optimized", "Fully Optimized Button"),
    ]

    @MainActor
    private func assertExpectedSectionTitleExists() {
        let el = app.staticTexts[Self.expectedSectionTitle].firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: 2.0), "Section title '\(Self.expectedSectionTitle)' should exist")
        XCTAssertFalse(el.label.isEmpty, "Section title should have non-empty accessibility label")
    }

    /// Asserts that the UI that names the Layer 6 optimization APIs is present.
    @MainActor
    private func assertLayer6FunctionNamesPresent() {
        for description in Self.layer6FunctionDescriptions {
            let el = app.staticTexts[description].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 2.0),
                          "Layer 6 demo for '\(description)' should be visible")
        }
    }

    @MainActor
    private func assertDemoButtonsMeetAccessibilityContract() {
        for (idSuffix, label) in Self.expectedButtons {
            let frameworkId = "SixLayer.main.ui.\(idSuffix).Button"
            let el = app.buttons[frameworkId].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 2.0), "Demo button '\(label)' (id: \(idSuffix)) should exist")
            el.verifyAccessibilityContract(elementName: "\(label) (\(idSuffix))", expectedType: .button)
            XCTAssertTrue(el.isEnabled, "Demo button '\(label)' (\(idSuffix)) should be enabled")
        }
    }

    @MainActor
    func testLayer6Examples_PrescriptiveAccessibility() throws {
        assertExpectedSectionTitleExists()
        assertLayer6FunctionNamesPresent()
        assertDemoButtonsMeetAccessibilityContract()
    }
}
