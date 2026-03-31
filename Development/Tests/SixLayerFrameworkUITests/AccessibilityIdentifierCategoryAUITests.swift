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
        let manual = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "CatA_ManualOnly_StaticText"))
            .firstMatch
        XCTAssertTrue(manual.waitForExistence(timeout: 12.0),
                      "Manual-only accessibility identifier should be visible to XCTest")
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
}
