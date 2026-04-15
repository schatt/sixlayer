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
                localApp.staticTexts[Copy.coverageTitle].waitForExistence(timeout: 6.0),
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
    private func scrollUntilVisible(_ text: String, attempts: Int = 10) -> XCUIElement {
        let target = app.staticTexts[text].firstMatch
        if target.waitForExistence(timeout: 1.0) { return target }
        for _ in 0..<attempts {
            app.xcuiSwipeScrollHostsUp()
            if target.waitForExistence(timeout: 0.5) { return target }
        }
        return target
    }

    func testCategoryB_defaultDetailView_showsTitleAndSubtitle() throws {
        XCTAssertTrue(scrollUntilVisible(Copy.defaultTitle).exists, "Default detail title should be visible")
        XCTAssertTrue(scrollUntilVisible(Copy.defaultSubtitle).exists, "Default detail subtitle should be visible")
    }

    func testCategoryB_customFieldView_showsCustomMarker() throws {
        XCTAssertTrue(
            scrollUntilVisible(Copy.customFieldPrefix).exists,
            "Custom field rendering should expose the custom marker text"
        )
    }

    func testCategoryB_nilValueData_showsRemainingVisibleContent() throws {
        XCTAssertTrue(scrollUntilVisible(Copy.nilTitle).exists, "Nil-value detail title should be visible")
        XCTAssertTrue(scrollUntilVisible(Copy.nilDescription).exists, "Nil-value detail description should be visible")
    }
}
