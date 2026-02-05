//
//  Layer6UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 6 (System) UI tests: launch with -OpenLayer6Examples so the app opens
//  directly to the Cross-Platform Optimizations section; prescriptive a11y via DRY helpers.
//

import XCTest
@testable import SixLayerFramework

/// Layer 6 system example tests. Prescriptive: require expected elements and full accessibility contract.
/// Uses launch argument -OpenLayer6Examples so the test app opens on the right screen.
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

    /// All four framework buttons on the direct-open screen: (id passed to platformButton, label for assertions).
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

    @MainActor
    private func assertExpectedButtonsExistAndMeetContract() {
        for (idSuffix, label) in Self.expectedButtons {
            let frameworkId = "SixLayer.main.ui.\(idSuffix).Button"
            let el = app.buttons[frameworkId].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 2.0), "Button '\(label)' (id: \(idSuffix)) should exist")
            el.verifyAccessibilityIdentifier(elementName: "\(label) (\(idSuffix))")
            el.verifyAccessibilityLabel(elementName: "\(label) (\(idSuffix))")
            el.verifyAccessibilityTraits(elementName: "\(label) (\(idSuffix))", expectedType: .button)
            XCTAssertTrue(el.isEnabled, "Button '\(label)' (\(idSuffix)) should be enabled")
        }
    }

    @MainActor
    func testLayer6Examples_PrescriptiveAccessibility() throws {
        assertExpectedSectionTitleExists()
        assertExpectedButtonsExistAndMeetContract()
    }
}
