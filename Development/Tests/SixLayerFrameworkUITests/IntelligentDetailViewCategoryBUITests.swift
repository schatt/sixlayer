//
//  IntelligentDetailViewCategoryBUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #198: Category B UI backfill for IntelligentDetailView visible content.
//

import XCTest

@MainActor
final class IntelligentDetailViewCategoryBUITests: XCTestCase {
    private enum Copy {
        static let coverageTitle = "Category B Detail Coverage"
        static let defaultTitle = "Category B Item"
        static let defaultSubtitle = "Category B Subtitle"
        static let customFieldPrefix = "Custom Field:"
        static let nilTitle = "Nil Item"
        static let nilDescription = "Nil Description"
        static let nilSectionHeader = "Nil Value IntelligentDetailView"
    }

    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenDetailViewCategoryB")
            localApp.launch()
            instance.app = localApp

            XCTAssertTrue(
                localApp.staticTexts[Copy.coverageTitle].waitForExistence(timeout: 2.5),
                "Category B host should appear with -OpenDetailViewCategoryB"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    @MainActor
    private func textVisible(_ text: String, timeout: TimeInterval) -> Bool {
        if app.staticTexts[text].waitForExistence(timeout: min(timeout, 0.6)) {
            return true
        }
        // Avoid value CONTAINS on `.any` — it can hang for minutes on macOS (#316).
        let labelPred = NSPredicate(format: "label CONTAINS[c] %@", text)
        let root: XCUIElement = app.windows.firstMatch.exists ? app.windows.firstMatch : app
        if root.descendants(matching: .staticText).matching(labelPred).firstMatch.waitForExistence(timeout: min(timeout, 0.35)) {
            return true
        }
        if root.descendants(matching: .other).matching(labelPred).firstMatch.waitForExistence(timeout: min(timeout, 0.35)) {
            return true
        }
        let valuePred = NSPredicate(format: "value == %@", text)
        return root.descendants(matching: .any).matching(valuePred).firstMatch.waitForExistence(timeout: min(timeout, 0.35))
    }

    @MainActor
    private func scrollUntilVisible(_ text: String, attempts: Int = 10) -> Bool {
        if textVisible(text, timeout: 1.0) { return true }
        // Do not swipe IntelligentDetail's inner ScrollView (last host) — that scrolls within a
        // card and can hide sibling fields. Window-level swipe moves the outer page (#316).
        for _ in 0..<attempts {
            if app.windows.firstMatch.exists {
                app.windows.firstMatch.swipeUp()
            } else {
                app.swipeUp()
            }
            if textVisible(text, timeout: 0.5) { return true }
        }
        return textVisible(text, timeout: 0.5)
    }

    func testCategoryB_defaultDetailView_showsTitleAndSubtitle() throws {
        XCTAssertTrue(scrollUntilVisible(Copy.defaultTitle), "Default detail title should be visible")
        XCTAssertTrue(scrollUntilVisible(Copy.defaultSubtitle), "Default detail subtitle should be visible")
    }

    func testCategoryB_customFieldView_showsCustomMarker() throws {
        XCTAssertTrue(
            scrollUntilVisible(Copy.customFieldPrefix),
            "Custom field rendering should expose the custom marker text"
        )
    }

    func testCategoryB_nilValueData_showsRemainingVisibleContent() throws {
        // Nil-value detail is below default + custom sections; allow more scroll attempts.
        XCTAssertTrue(
            scrollUntilVisible(Copy.nilSectionHeader, attempts: 16),
            "Nil-value section header should be visible after scrolling"
        )
        XCTAssertTrue(scrollUntilVisible(Copy.nilTitle, attempts: 8), "Nil-value detail title should be visible")
        XCTAssertTrue(scrollUntilVisible(Copy.nilDescription, attempts: 8), "Nil-value detail description should be visible")
    }
}
