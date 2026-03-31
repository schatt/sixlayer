//
//  AccessibilityIdentifierCategoryAUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: Category A — accessibility identifier scenarios assertable via XCUITest
//  (unicode, nested named, manual-only, special chars, long names). Launch: -OpenCategoryAAccessibility.
//

import XCTest

@MainActor
final class AccessibilityIdentifierCategoryAUITests: XCTestCase {
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            guard Self.sharedApp == nil else { return }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenCategoryAAccessibility")
            localApp.launch()
            Self.sharedApp = localApp
            XCTAssertTrue(
                localApp.navigationBars["Category A Audit"].waitForExistence(timeout: 8.0),
                "App should open on Category A Audit (launch arg -OpenCategoryAAccessibility)"
            )
        }
    }

    private func anyElement(identifierContains substring: String) -> XCUIElement {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        return app.descendants(matching: .any).matching(pred).firstMatch
    }

    /// Scroll until an element whose identifier contains `substring` exists (below-the-fold content).
    private func scrollUntilIdentifierContains(_ substring: String, maxSwipes: Int = 16) -> Bool {
        scrollUntil(
            matching: NSPredicate(format: "identifier CONTAINS[c] %@", substring),
            maxSwipes: maxSwipes
        )
    }

    /// Scroll until an element whose identifier equals `exact` (e.g. `exactNamed` minimal IDs).
    private func scrollUntilIdentifierEquals(_ exact: String, maxSwipes: Int = 16) -> Bool {
        scrollUntil(
            matching: NSPredicate(format: "identifier == %@", exact),
            maxSwipes: maxSwipes
        )
    }

    /// Scroll until an element whose accessibility label contains `substring`.
    private func scrollUntilLabelContains(_ substring: String, maxSwipes: Int = 16) -> Bool {
        scrollUntil(
            matching: NSPredicate(format: "label CONTAINS[c] %@", substring),
            maxSwipes: maxSwipes
        )
    }

    private func scrollUntil(matching pred: NSPredicate, maxSwipes: Int) -> Bool {
        if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: 1.0) {
            return true
        }
        let scroll = app.scrollViews.firstMatch
        guard scroll.exists else { return false }
        for _ in 0..<maxSwipes {
            scroll.swipeUp()
            if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: 0.5) {
                return true
            }
        }
        return false
    }

    func testCategoryA_unicodeText_hasAccessibilityIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAUnicodeText").waitForExistence(timeout: 12.0),
            "Unicode identifier name should appear in runtime accessibility identifier (Category A)"
        )
    }

    func testCategoryA_nestedNamed_outerAndInner_haveIdentifiers() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatANestedOuter").waitForExistence(timeout: 12.0),
            "Outer named component should contribute to identifier"
        )
        XCTAssertTrue(
            anyElement(identifierContains: "CatANestedInnerButton").waitForExistence(timeout: 12.0),
            "Inner named component should contribute to identifier"
        )
    }

    func testCategoryA_manualOnlyStaticText_exactIdentifier() throws {
        XCTAssertTrue(
            scrollUntilIdentifierContains("CatA_ManualOnly_StaticText"),
            "Manual-only id (platformButton id:) should appear after scrolling the audit screen"
        )
    }

    func testCategoryA_specialCharsInLabel_hasIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatASpecialChars").waitForExistence(timeout: 12.0),
            "Special characters in label should still yield a stable identifier substring"
        )
    }

    func testCategoryA_longIdentifierName_hasStablePrefixInIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatALong").waitForExistence(timeout: 12.0),
            "Long identifier name should be represented in accessibility identifier (sanitized prefix)"
        )
    }

    func testCategoryA_auditTitle_namedComponent() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAAuditTitle").waitForExistence(timeout: 12.0),
            "Headline named title should expose identifier for UITest"
        )
    }

    func testCategoryA_exactNamed_minimalIdentifier() throws {
        XCTAssertTrue(
            scrollUntilIdentifierEquals("CatAExactNamed"),
            "exactNamed should set identifier to the literal name (no SixLayer prefix)"
        )
    }

    func testCategoryA_accessibilityLabel_parameter_surfacesInLabel() throws {
        XCTAssertTrue(
            scrollUntilLabelContains("VoiceOver Cat A Label"),
            "basicAutomaticCompliance accessibilityLabel should appear on XCUIElement label"
        )
        XCTAssertTrue(
            anyElement(identifierContains: "CatALabelAndId").waitForExistence(timeout: 8.0),
            "identifier should still include CatALabelAndId when accessibilityLabel is set"
        )
    }

    func testCategoryA_manualOnOuterGroup_overridesWrapper() throws {
        XCTAssertTrue(
            scrollUntilIdentifierContains("CatAManualWinsOnOuter"),
            "outer Group accessibilityIdentifier should be findable (manual override on wrapper)"
        )
    }
}
