//
//  Layer5UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 5 (Optimization) UI tests: launch with -OpenLayer5Accessibility so the app opens
//  directly to the Accessibility Features section; no navigation or scrolling.
//

import XCTest
@testable import SixLayerFramework

/// Layer 5 optimization example tests. Prescriptive: require expected elements to exist and have required accessibility.
/// Uses launch argument -OpenLayer5Accessibility so the test app opens on the right screen.
@MainActor
final class Layer5UITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer5Accessibility")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 5 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 5 Accessibility (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
        try super.tearDownWithError()
    }

    /// Section title on the direct-open screen (only the Accessibility Features section is shown).
    private static let expectedSectionTitle = "Accessibility Features"

    /// Expected button labels in the Accessibility Features section (platformButton titles).
    private static let expectedAccessibilityButtonLabels = [
        "Accessible Button",
        "VoiceOver Button",
        "Keyboard Button",
        "High Contrast Button",
    ]

    /// Sanitized form of label for framework-generated identifier (e.g. "Accessible Button" -> "accessible-button").
    private static func frameworkIdentifierSuffix(for label: String) -> String {
        label.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
    }

    @MainActor
    private func assertExpectedSectionTitleExists() {
        let el = app.staticTexts[Self.expectedSectionTitle].firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: 2.0), "Section title '\(Self.expectedSectionTitle)' should exist")
        XCTAssertFalse(el.label.isEmpty, "Section title should have non-empty accessibility label")
    }

    @MainActor
    private func assertExpectedAccessibilityButtonsExistAndAreAccessible() {
        for label in Self.expectedAccessibilityButtonLabels {
            let frameworkId = "SixLayer.main.ui.\(Self.frameworkIdentifierSuffix(for: label)).Button"
            let el = app.buttons[frameworkId].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 2.0), "Button '\(label)' should exist (identifier: \(frameworkId))")
            el.verifyAccessibilityIdentifier(elementName: label)
            el.verifyAccessibilityLabel(elementName: label)
            el.verifyAccessibilityTraits(elementName: label, expectedType: .button)
            XCTAssertTrue(el.isEnabled, "Button '\(label)' should be enabled")
        }
    }

    @MainActor
    func testLayer5Examples_PrescriptiveAccessibility() throws {
        assertExpectedSectionTitleExists()
        assertExpectedAccessibilityButtonsExistAndAreAccessible()
    }
}
