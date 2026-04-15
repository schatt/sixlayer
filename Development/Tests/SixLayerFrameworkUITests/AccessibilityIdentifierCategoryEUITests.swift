//
//  AccessibilityIdentifierCategoryEUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #201: Category E one-off UI backfill.
//  Strict TDD red phase: this suite should fail until the Category E host is wired in TestApp.
//

import XCTest

@MainActor
final class AccessibilityIdentifierCategoryEUITests: XCTestCase {
    private enum IDs {
        static let hostTitle = "Category E One-Off Coverage"
        static let explicitEnableRow = "category-e-explicit-enable-row"
        static let optOutRow = "category-e-opt-out-row"
    }

    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenCategoryEOneOffs")
            localApp.launch()
            instance.app = localApp

            XCTAssertTrue(
                localApp.staticTexts[IDs.hostTitle].waitForExistence(timeout: 6.0),
                "Category E host should appear with -OpenCategoryEOneOffs"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    func testCategoryE_explicitEnable_generatesIdentifierForPlainSwiftUIView() throws {
        XCTAssertTrue(
            app.descendants(matching: .any)[IDs.explicitEnableRow].waitForExistence(timeout: 4.0),
            "Explicit-enable row should expose an accessibility identifier for the plain SwiftUI subtree"
        )
    }

    func testCategoryE_optOut_disablesAutomaticIdentifierForTargetRow() throws {
        XCTAssertFalse(
            app.descendants(matching: .any)[IDs.optOutRow].exists,
            "Opt-out row should not expose the suppressed automatic identifier"
        )
    }
}
