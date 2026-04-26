//
//  PlatformAdvancedContainersAccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #257: explicit list accessibility identifier should remain queryable.
//

import XCTest

@MainActor
final class PlatformAdvancedContainersAccessibilityUITests: XCTestCase {
    private static let quickWait: TimeInterval = 0.5
    private static let rootReadyTimeout: TimeInterval = 2.0
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
                .waitForExistence(timeout: Self.rootReadyTimeout),
            "Platform advanced containers audit host should open"
        )

        XCTAssertTrue(
            app.scrollViews[IDs.explicitListID].waitForExistence(timeout: Self.quickWait),
            "Explicit list accessibility identifier should be queryable as scrollView"
        )
    }
}
