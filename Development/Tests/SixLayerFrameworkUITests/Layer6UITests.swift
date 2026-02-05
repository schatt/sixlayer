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
/// Tests run on a single platform per run; use compile-time conditionals (#if os(iOS), os(macOS), os(watchOS), os(tvOS), os(visionOS)) in the test to assert platform-specific Layer 6 behavior when needed.
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

    /// L6 modifiers apply to the element they wrap; automaticCompliance runs only on that element.
    /// Assert that the plain Text and Button that have ONLY .platformSpecificOptimizations applied get a11y from the modifier.
    @MainActor
    private func assertL6ModifierContract_ElementsGetComplianceFromModifier() {
        let textEl = app.staticTexts["L6ContractText"].firstMatch
        XCTAssertTrue(textEl.waitForExistence(timeout: 2.0), "L6 contract: Text with only L6 modifier should exist")
        XCTAssertFalse(textEl.identifier.isEmpty,
                       "L6 modifier must apply a11y to the view it wraps; L6ContractText should have identifier from modifier's automaticCompliance. Found: '\(textEl.identifier)'")

        let buttonEl = app.buttons["L6ContractButton"].firstMatch
        XCTAssertTrue(buttonEl.waitForExistence(timeout: 2.0), "L6 contract: Button with only L6 modifier should exist")
        XCTAssertFalse(buttonEl.identifier.isEmpty,
                       "L6 modifier must apply a11y to the view it wraps; L6ContractButton should have identifier from modifier's automaticCompliance. Found: '\(buttonEl.identifier)'")
    }

    /// Platform-specific Layer 6 checks. Each platform's Layer 6 code path is tested when this target runs on that platform.
    @MainActor
    private func assertLayer6PlatformSpecificBehavior() {
        #if os(iOS)
        // iOS: Navigation Stack Enhancements section uses platformIOSNavigationStackEnhancements_L6()
        let navStackSection = app.staticTexts["Navigation Stack Enhancements"].firstMatch
        XCTAssertTrue(navStackSection.waitForExistence(timeout: 2.0),
                      "iOS Layer 6: Navigation Stack Enhancements section should be visible")
        #elseif os(macOS)
        // macOS: Navigation Stack Enhancements section uses platformMacOSNavigationStackEnhancements_L6()
        let navStackSection = app.staticTexts["Navigation Stack Enhancements"].firstMatch
        XCTAssertTrue(navStackSection.waitForExistence(timeout: 2.0),
                      "macOS Layer 6: Navigation Stack Enhancements section should be visible")
        #elseif os(tvOS)
        // tvOS: Layer 6 dispatcher returns self for nav stack; Cross-Platform Optimizations still apply
        XCTAssertTrue(app.staticTexts[Self.expectedSectionTitle].waitForExistence(timeout: 2.0),
                      "tvOS Layer 6: Cross-Platform Optimizations section should be visible")
        #elseif os(watchOS)
        // watchOS: same as tvOS for shared optimization section
        XCTAssertTrue(app.staticTexts[Self.expectedSectionTitle].waitForExistence(timeout: 2.0),
                      "watchOS Layer 6: Cross-Platform Optimizations section should be visible")
        #elseif os(visionOS)
        // visionOS: same as tvOS for shared optimization section
        XCTAssertTrue(app.staticTexts[Self.expectedSectionTitle].waitForExistence(timeout: 2.0),
                      "visionOS Layer 6: Cross-Platform Optimizations section should be visible")
        #endif
    }

    @MainActor
    func testLayer6Examples_PrescriptiveAccessibility() throws {
        assertL6ModifierContract_ElementsGetComplianceFromModifier()
        assertExpectedSectionTitleExists()
        assertLayer6FunctionNamesPresent()
        assertLayer6PlatformSpecificBehavior()
    }
}
