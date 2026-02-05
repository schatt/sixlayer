//
//  Layer5UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 5 (Optimization) UI tests: one launch, navigate to L5 Examples → prescriptive accessibility asserts.
//

import XCTest
@testable import SixLayerFramework

/// Layer 5 optimization example tests. Prescriptive: require expected elements to exist and have required accessibility.
@MainActor
final class Layer5UITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.launchWithOptimizations()
            instance.app = localApp
            XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
        try super.tearDownWithError()
    }

    @MainActor
    private func navigateToLayer5Examples() throws {
        guard app.navigateToLayerExamples(linkIdentifier: "layer5-examples-link", navigationBarTitle: "Layer 5 Examples") else {
            XCTFail("Should navigate to Layer 5 Examples")
            return
        }
    }

    /// Expected section titles on Layer 5 Examples (from Layer5ExamplesView).
    private static let expectedSectionTitles = [
        "Navigation Stack Optimizations",
        "Split View Optimizations",
        "Accessibility Features",
    ]

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
    private func scrollLayer5ToAccessibilitySection() {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else { return }
        // Swipe up to bring "Accessibility Features" and the four buttons into view (section is near bottom).
        for _ in 0..<6 {
            scrollView.swipeUp()
        }
        // Brief wait for layout to settle after scrolling.
        _ = app.staticTexts["Accessibility Features"].firstMatch.waitForExistence(timeout: 3.0)
    }

    @MainActor
    private func assertExpectedSectionTitlesExist() {
        for title in Self.expectedSectionTitles {
            // Use firstMatch: section titles may appear more than once (e.g. section header and card title).
            let el = app.staticTexts[title].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 5.0), "Section title '\(title)' should exist and be visible (scroll if needed)")
            XCTAssertFalse(el.label.isEmpty, "Section title should have non-empty accessibility label")
        }
    }

    @MainActor
    private func assertExpectedAccessibilityButtonsExistAndAreAccessible() {
        // Require each of the four Accessibility Features buttons: must exist and be accessible (enabled, non-empty label).
        // Framework exposes them via platformButton(...) with that label; may be Button or (on some platforms) another type.
        var foundCount = 0
        for label in Self.expectedAccessibilityButtonLabels {
            let asButton = app.buttons[label].firstMatch
            let asLink = app.links[label].firstMatch
            let existsAsButton = asButton.waitForExistence(timeout: 3.0)
            let existsAsLink = !existsAsButton && asLink.waitForExistence(timeout: 1.0)
            let el: XCUIElement? = existsAsButton ? asButton : (existsAsLink ? asLink : nil)
            if let element = el {
                XCTAssertTrue(element.isEnabled, "Element '\(label)' should be enabled")
                XCTAssertFalse(element.label.isEmpty, "Element '\(label)' should have non-empty accessibility label")
                foundCount += 1
                continue
            }
            // Fallback 1: any descendant with this label (e.g. if exposed as Other with button trait).
            let byLabel = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
            if byLabel.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(byLabel.isEnabled, "Element '\(label)' should be enabled")
                XCTAssertFalse(byLabel.label.isEmpty, "Element '\(label)' should have non-empty accessibility label")
                foundCount += 1
                continue
            }
            // Fallback 2: framework-generated identifier (e.g. SixLayer.main.ui.accessible-button.Button).
            let suffix = Self.frameworkIdentifierSuffix(for: label)
            let frameworkId = "SixLayer.main.ui.\(suffix).Button"
            if let byId = app.findElement(byIdentifier: frameworkId, primaryType: .button, secondaryTypes: [.other, .any], timeout: 2.0),
               byId.waitForExistence(timeout: 1.0) {
                XCTAssertTrue(byId.isEnabled, "Element '\(label)' should be enabled")
                XCTAssertFalse(byId.label.isEmpty, "Element '\(label)' should have non-empty accessibility label")
                foundCount += 1
            }
        }
        XCTAssertEqual(foundCount, Self.expectedAccessibilityButtonLabels.count,
                      "All four Accessibility Features buttons should exist and be accessible; found \(foundCount) of \(Self.expectedAccessibilityButtonLabels.count)")
    }

    @MainActor
    func testLayer5Examples_PrescriptiveAccessibility() throws {
        try navigateToLayer5Examples()
        XCTAssertTrue(app.navigationBars["Layer 5 Examples"].waitForExistence(timeout: 5.0), "Layer 5 Examples screen should show navigation bar")
        scrollLayer5ToAccessibilitySection()
        assertExpectedSectionTitlesExist()
        assertExpectedAccessibilityButtonsExistAndAreAccessible()
    }
}
