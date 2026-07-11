//
//  AccessibilityIdentifierCategoryAGlobalOffUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: When global automatic IDs are off, basicAutomaticCompliance should not emit
//  framework identifiers; explicit .named / .exactNamed should still apply.
//  Launch: -OpenCategoryAAccessibility -CategoryAGlobalAutoOff
//

import XCTest

@MainActor
final class AccessibilityIdentifierCategoryAGlobalOffUITests: XCTestCase {
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
            localApp.launchArguments.append("-CategoryAGlobalAutoOff")
            localApp.launch()
            Self.sharedApp = localApp
            // macOS often does not expose NavigationStack titles as navigationBars (#316).
            let landed =
                localApp.navigationBars["Category A Global Off"].waitForExistence(timeout: 2.5)
                || localApp.staticTexts["Category A — global automatic IDs off"].waitForExistence(timeout: 2.0)
                || localApp.descendants(matching: .any)
                    .matching(NSPredicate(format: "label CONTAINS[c] %@", "global automatic IDs off"))
                    .firstMatch.waitForExistence(timeout: 1.5)
                || localApp.descendants(matching: .any)
                    .matching(NSPredicate(format: "identifier CONTAINS[c] %@", "CatAGlobalOffTitle"))
                    .firstMatch.waitForExistence(timeout: 2.0)
            XCTAssertTrue(
                landed,
                "App should open Category A Global Off audit (launch args -OpenCategoryAAccessibility -CategoryAGlobalAutoOff)"
            )
        }
    }

    private func anyElement(identifierContains substring: String) -> XCUIElement {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        return app.descendants(matching: .any).matching(pred).firstMatch
    }

    private func anyElement(identifierEquals exact: String) -> XCUIElement {
        let pred = NSPredicate(format: "identifier == %@", exact)
        return app.descendants(matching: .any).matching(pred).firstMatch
    }

    /// Asserts no descendant has an accessibility identifier containing `substring`.
    private func assertNoIdentifierContaining(_ substring: String, file: StaticString = #filePath, line: UInt = #line) {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        let first = app.descendants(matching: .any).matching(pred).firstMatch
        XCTAssertFalse(
            first.waitForExistence(timeout: 1.0),
            "Unexpected element with identifier containing \(substring)",
            file: file,
            line: line
        )
    }

    func testCategoryAGlobalOff_basicAutomaticCompliance_doesNotEmitSuppressedName() throws {
        assertNoIdentifierContaining("CatAAutoSuppressed")
    }

    func testCategoryAGlobalOff_named_stillSurfacesIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatANamedWhenGlobalOff").waitForExistence(timeout: 2.5),
            ".named should still apply when global automatic IDs are off"
        )
    }

    func testCategoryAGlobalOff_exactNamed_stillMinimalIdentifier() throws {
        XCTAssertTrue(
            anyElement(identifierEquals: "CatAExactWhenGlobalOff").waitForExistence(timeout: 2.5),
            ".exactNamed should still set literal identifier when global automatic IDs are off"
        )
    }

    func testCategoryAGlobalOff_namedTitle_rowLoads() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAGlobalOffTitle").waitForExistence(timeout: 2.5),
            "Headline with automaticCompliance(named:) should still expose an identifier on this screen"
        )
    }
}
