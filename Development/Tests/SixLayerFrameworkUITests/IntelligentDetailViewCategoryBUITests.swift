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
        // Prefer label/value match scoped to window — full-tree `.any` value CONTAINS can hang (#316).
        let pred = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@ OR title CONTAINS[c] %@",
            text, text, text
        )
        let root = app.windows.firstMatch.exists ? app.windows.firstMatch : app
        let match = root.descendants(matching: .any).matching(pred).firstMatch
        let deadline = Date().addingTimeInterval(min(timeout, 0.6))
        while Date() < deadline {
            if match.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
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
        XCTAssertTrue(scrollUntilVisible(Copy.nilTitle, attempts: 16), "Nil-value detail title should be visible")
        XCTAssertTrue(scrollUntilVisible(Copy.nilDescription, attempts: 8), "Nil-value detail description should be visible")
    }
}
