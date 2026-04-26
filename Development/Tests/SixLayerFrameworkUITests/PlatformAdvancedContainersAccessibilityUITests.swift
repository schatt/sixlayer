//
//  PlatformAdvancedContainersAccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #257: explicit list accessibility identifier should remain queryable.
//

import XCTest

@MainActor
final class PlatformAdvancedContainersAccessibilityUITests: XCTestCase {
    private enum IDs {
        static let hostTitle = "platform-advanced-containers-audit-title"
        static let explicitListID = "platform-advanced-list-host"
    }

    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenPlatformAdvancedContainersExtensions")
            localApp.launch()
            instance.app = localApp
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    func testIssue257_explicitPlatformListContainerIdentifier_isQueryableViaScrollViewContract() throws {
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier == %@", IDs.hostTitle))
                .firstMatch
                .waitForExistence(timeout: 6.0),
            "Platform advanced containers audit host should open"
        )

        XCTAssertFalse(
            app.scrollViews[IDs.explicitListID].waitForExistence(timeout: 8.0),
            "DELIBERATE RED: this assertion is intentionally inverted to prove the test fails when the contract is incorrect"
        )
    }
}
