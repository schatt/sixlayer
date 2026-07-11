//
//  IntelligentDetailViewCategoryBUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #198: Category B UI backfill for IntelligentDetailView visible content.
//  Content must be in the accessibility tree at launch — do not scroll to find it (#316).
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

    /// True when any a11y node exposes `text` via label, exact value, or title (no scrolling).
    /// Avoids app-wide `value CONTAINS` — that query can hang for minutes on macOS (#316).
    @MainActor
    private func assertAccessibleTextExists(_ text: String, timeout: TimeInterval = 2.0, _ message: String) {
        if app.staticTexts[text].waitForExistence(timeout: timeout) {
            return
        }
        let labelPred = NSPredicate(format: "label CONTAINS[c] %@", text)
        if app.descendants(matching: .staticText).matching(labelPred).firstMatch.waitForExistence(timeout: timeout) {
            return
        }
        if app.descendants(matching: .other).matching(labelPred).firstMatch.waitForExistence(timeout: timeout) {
            return
        }
        let exactPred = NSPredicate(format: "value == %@ OR title == %@", text, text)
        XCTAssertTrue(
            app.descendants(matching: .any).matching(exactPred).firstMatch.waitForExistence(timeout: timeout),
            message
        )
    }

    func testCategoryB_defaultDetailView_showsTitleAndSubtitle() throws {
        assertAccessibleTextExists(Copy.defaultTitle, "Default detail title should be in the accessibility tree")
        assertAccessibleTextExists(Copy.defaultSubtitle, "Default detail subtitle should be in the accessibility tree")
    }

    func testCategoryB_customFieldView_showsCustomMarker() throws {
        let byId = app.descendants(matching: .any)["category-b-custom-field"]
        if byId.waitForExistence(timeout: 2.0) {
            XCTAssertTrue(
                byId.xcuiAccessibleText.contains(Copy.customFieldPrefix),
                "Custom field identifier should expose marker text; got '\(byId.xcuiAccessibleText)'"
            )
            return
        }
        assertAccessibleTextExists(
            Copy.customFieldPrefix,
            "Custom field rendering should expose the custom marker text"
        )
    }

    func testCategoryB_nilValueData_showsRemainingVisibleContent() throws {
        assertAccessibleTextExists(Copy.nilTitle, "Nil-value detail title should be in the accessibility tree")
        assertAccessibleTextExists(Copy.nilDescription, "Nil-value detail description should be in the accessibility tree")
    }
}
