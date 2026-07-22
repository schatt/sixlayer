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
            if let existing = Self.sharedApp, existing.state == .runningForeground {
                return
            }
            if let running = Self.sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5)
            }
            Self.sharedApp = nil

            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenCategoryAAccessibility")
            localApp.launchArguments.append("-CategoryAGlobalAutoOff")
            localApp.launch()
            XCTAssertTrue(
                localApp.waitForHostRootIdentifier("category-a-global-off-host-root", timeout: 8.0),
                "App should open Category A Global Off audit (launch args -OpenCategoryAAccessibility -CategoryAGlobalAutoOff)"
            )
            // Assign only after host land succeeds — poisoned sharedApp skips relaunch (#370).
            Self.sharedApp = localApp
        }
    }

    override class func tearDown() {
        if let running = sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        sharedApp = nil
        super.tearDown()
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
            anyElement(identifierEquals: "CatAGlobalOffTitle").waitForExistence(timeout: 2.5),
            "Headline with exactNamed(CatAGlobalOffTitle) should expose the literal identifier"
        )
    }
}
