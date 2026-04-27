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
    private static let quickWait: TimeInterval = 0.4
    private static let mediumWait: TimeInterval = 0.75
    private static let rootReadyTimeout: TimeInterval = 2.0
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            if Self.sharedApp == nil {
                let localApp = XCUIApplication()
                localApp.configureForFastTesting()
                localApp.launchArguments.append("-OpenCategoryAAccessibility")
                localApp.launch()
                Self.sharedApp = localApp
                XCTAssertTrue(
                    localApp.navigationBars["Category A Audit"].waitForExistence(timeout: Self.rootReadyTimeout)
                        || localApp.staticTexts["Category A Audit"].waitForExistence(timeout: Self.quickWait),
                    "App should open on Category A Audit (launch arg -OpenCategoryAAccessibility)"
                )
            }
            guard let app = Self.sharedApp else { return }
            // Shared app + alphabetical test order: a test that scrolls down (e.g. exactNamed) leaves the next test
            // with top content off-screen and often missing from the a11y tree. Reset once per test instead of ad-hoc swipes.
            Self.resetCategoryAAuditScrollToTop(app: app)
        }
    }

    /// Swipe down on the scroll host until top audit anchors appear. No-op when already at top.
    private static func resetCategoryAAuditScrollToTop(app: XCUIApplication, maxSwipes: Int = 24) {
        let manualPred = NSPredicate(format: "identifier CONTAINS[c] %@", "CatAManualWinsOnOuter")
        let titlePred = NSPredicate(format: "identifier CONTAINS[c] %@", "CatAAuditTitle")
        if app.descendants(matching: .any).matching(manualPred).firstMatch.waitForExistence(timeout: 0.5) { return }
        if app.descendants(matching: .any).matching(titlePred).firstMatch.waitForExistence(timeout: 0.5) { return }
        for _ in 0..<maxSwipes {
            app.xcuiSwipeScrollHostsDown()
            if app.descendants(matching: .any).matching(manualPred).firstMatch.waitForExistence(timeout: 0.35) { return }
            if app.descendants(matching: .any).matching(titlePred).firstMatch.waitForExistence(timeout: 0.35) { return }
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
        if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: Self.mediumWait) {
            return true
        }
        for _ in 0..<maxSwipes {
            app.xcuiSwipeScrollHostsUp()
            if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: Self.quickWait) {
                return true
            }
        }
        let window = app.windows.firstMatch
        guard window.exists else { return false }
        for _ in 0..<maxSwipes {
            window.swipeUp()
            if app.descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: Self.quickWait) {
                return true
            }
        }
        return false
    }

    /// Asserts no descendant has an accessibility identifier containing `substring` (scrolls to search).
    private func assertNoIdentifierContaining(_ substring: String, maxSwipes: Int = 20, file: StaticString = #filePath, line: UInt = #line) {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        let first = app.descendants(matching: .any).matching(pred).firstMatch
        if first.waitForExistence(timeout: Self.mediumWait) {
            XCTFail("Unexpected element with identifier containing \(substring)", file: file, line: line)
            return
        }
        for _ in 0..<maxSwipes {
            app.xcuiSwipeScrollHostsUp()
            let el = app.descendants(matching: .any).matching(pred).firstMatch
            if el.waitForExistence(timeout: Self.quickWait) {
                XCTFail("Unexpected identifier containing \(substring) after scroll", file: file, line: line)
                return
            }
        }
        let window = app.windows.firstMatch
        guard window.exists else { return }
        for _ in 0..<maxSwipes {
            window.swipeUp()
            let el = app.descendants(matching: .any).matching(pred).firstMatch
            if el.waitForExistence(timeout: Self.quickWait) {
                XCTFail("Unexpected identifier containing \(substring) after window swipe", file: file, line: line)
                return
            }
        }
    }

    func testCategoryA_unicodeText_hasAccessibilityIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAUnicodeText").waitForExistence(timeout: Self.mediumWait),
            "Unicode identifier name should appear in runtime accessibility identifier (Category A)"
        )
    }

    func testCategoryA_nestedNamed_outerAndInner_haveIdentifiers() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatANestedOuter").waitForExistence(timeout: Self.mediumWait),
            "Outer named component should contribute to identifier"
        )
        XCTAssertTrue(
            anyElement(identifierContains: "CatANestedInnerButton").waitForExistence(timeout: Self.mediumWait),
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
            anyElement(identifierContains: "CatASpecialChars").waitForExistence(timeout: Self.mediumWait),
            "Special characters in label should still yield a stable identifier substring"
        )
    }

    func testCategoryA_longIdentifierName_hasStablePrefixInIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatALong").waitForExistence(timeout: Self.mediumWait),
            "Long identifier name should be represented in accessibility identifier (sanitized prefix)"
        )
    }

    func testCategoryA_auditTitle_namedComponent() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAAuditTitle").waitForExistence(timeout: Self.mediumWait),
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
            anyElement(identifierContains: "CatALabelAndId").waitForExistence(timeout: Self.mediumWait),
            "identifier should still include CatALabelAndId when accessibilityLabel is set"
        )
    }

    func testCategoryA_manualOnOuterGroup_overridesWrapper() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAManualWinsOnOuter").waitForExistence(timeout: Self.mediumWait),
            "outer Group accessibilityIdentifier should be findable (manual override on wrapper)"
        )
    }

    func testCategoryA_emptyIdentifierName_sanitizedLabelInIdentifier() throws {
        XCTAssertTrue(
            scrollUntilIdentifierContains("empty-name-row"),
            "Empty identifierName should still include sanitized identifierLabel in generated identifier"
        )
    }

    /// Category A audit: `basicAutomaticCompliance` name + sibling with explicit `platformButton` id (Issue #197).
    /// TestApp already enables global automatic IDs; avoid `enableGlobalAutomaticCompliance` in the audit view —
    /// it mutates shared config and can break sibling identifiers when rows scroll off-screen.
    func testCategoryA_midHierarchy_autoSiblingAndOptOut_identifiersPresent() throws {
        XCTAssertTrue(
            scrollUntilIdentifierContains("CatAMidAutoSibling"),
            "Named basicAutomaticCompliance row should expose identifier substring (scroll if below fold)"
        )
        XCTAssertTrue(
            scrollUntilIdentifierContains("CatAMid_LocalOptOut_Static"),
            "Explicit platformButton id should match manual-only row pattern on the audit scroll view"
        )
    }

    /// `disableAutomaticAccessibilityIdentifiers()` must suppress `basicAutomaticCompliance` in that subtree (#197).
    func testCategoryA_disableAutomatic_localSubtree_skipsBasicAutomaticIdentifier() throws {
        XCTAssertTrue(
            scrollUntilIdentifierContains("CatADisableMid_AutoPresent"),
            "Row outside disable wrapper should still expose basicAutomaticCompliance identifier"
        )
        assertNoIdentifierContaining("CatADisableMid_LocalAutoOff")
    }
}
