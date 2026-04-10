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
            XCTAssertTrue(
                localApp.navigationBars["Category A Global Off"].waitForExistence(timeout: 8.0),
                "App should open Category A Global Off audit (launch args -OpenCategoryAAccessibility -CategoryAGlobalAutoOff)"
            )
        }
    }

    private func anyElement(identifierContains substring: String) -> XCUIElement {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        return app.descendants(matching: .any).matching(pred).firstMatch
    }

    private func scrollUntilIdentifierContains(_ substring: String, maxSwipes: Int = 16) -> Bool {
        scrollUntil(
            matching: NSPredicate(format: "identifier CONTAINS[c] %@", substring),
            maxSwipes: maxSwipes
        )
    }

    private func scrollUntilIdentifierEquals(_ exact: String, maxSwipes: Int = 16) -> Bool {
        scrollUntil(
            matching: NSPredicate(format: "identifier == %@", exact),
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

    /// Asserts no descendant has an accessibility identifier containing `substring` (scrolls to search).
    private func assertNoIdentifierContaining(_ substring: String, maxSwipes: Int = 16, file: StaticString = #filePath, line: UInt = #line) {
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", substring)
        let first = app.descendants(matching: .any).matching(pred).firstMatch
        if first.waitForExistence(timeout: 1.0) {
            XCTFail("Unexpected element with identifier containing \(substring)", file: file, line: line)
            return
        }
        let scroll = app.scrollViews.firstMatch
        guard scroll.exists else { return }
        for _ in 0..<maxSwipes {
            scroll.swipeUp()
            let el = app.descendants(matching: .any).matching(pred).firstMatch
            if el.waitForExistence(timeout: 0.5) {
                XCTFail("Unexpected element with identifier containing \(substring) after scroll", file: file, line: line)
                return
            }
        }
    }

    func testCategoryAGlobalOff_basicAutomaticCompliance_doesNotEmitSuppressedName() throws {
        assertNoIdentifierContaining("CatAAutoSuppressed")
    }

    func testCategoryAGlobalOff_named_stillSurfacesIdentifier() throws {
        XCTAssertTrue(
            scrollUntilIdentifierContains("CatANamedWhenGlobalOff"),
            ".named should still apply when global automatic IDs are off"
        )
    }

    func testCategoryAGlobalOff_exactNamed_stillMinimalIdentifier() throws {
        XCTAssertTrue(
            scrollUntilIdentifierEquals("CatAExactWhenGlobalOff"),
            ".exactNamed should still set literal identifier when global automatic IDs are off"
        )
    }

    func testCategoryAGlobalOff_namedTitle_rowLoads() throws {
        XCTAssertTrue(
            anyElement(identifierContains: "CatAGlobalOffTitle").waitForExistence(timeout: 8.0),
            "Headline with automaticCompliance(named:) should still expose an identifier on this screen"
        )
    }
}
