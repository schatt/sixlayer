//
//  AccessibilityIdentifierCategoryEUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #201: Category E one-off UI backfill.
//  #373: one shared app process for the class (same launch args every method).
//

import XCTest

@MainActor
final class AccessibilityIdentifierCategoryEUITests: XCTestCase {
    private enum IDs {
        static let hostTitle = "Category E One-Off Coverage"
        static let explicitEnableRow = "category-e-explicit-enable-row"
        static let optOutRow = "category-e-opt-out-row"
        static let clipboardTriggerButton = "category-e-clipboard-generate-button"
        static let clipboardStateLabel = "category-e-clipboard-state-label"
    }

    var app: XCUIApplication!
    private static var sharedApp: XCUIApplication?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            if let existing = Self.sharedApp, existing.state == .runningForeground {
                instance.app = existing
                return
            }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenCategoryEOneOffs")
            localApp.launch()
            Self.sharedApp = localApp
            instance.app = localApp

            XCTAssertTrue(
                localApp.staticTexts[IDs.hostTitle].waitForExistence(timeout: 2.5),
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

    override class func tearDown() {
        MainActor.assumeIsolated {
            if let running = sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5)
            }
            sharedApp = nil
        }
        super.tearDown()
    }

    func testCategoryE_explicitEnable_generatesIdentifierForPlainSwiftUIView() throws {
        XCTAssertTrue(
            app.descendants(matching: .any)[IDs.explicitEnableRow].waitForExistence(timeout: 1.5),
            "Explicit-enable row should expose an accessibility identifier for the plain SwiftUI subtree"
        )
    }

    func testCategoryE_optOut_disablesAutomaticIdentifierForTargetRow() throws {
        XCTAssertFalse(
            app.descendants(matching: .any)[IDs.optOutRow].exists,
            "Opt-out row should not expose the suppressed automatic identifier"
        )
    }

    func testCategoryE_clipboardGeneration_updatesVisibleResultState() throws {
        let trigger = app.buttons[IDs.clipboardTriggerButton]
        XCTAssertTrue(trigger.waitForExistence(timeout: 1.5), "Clipboard generation trigger should exist")
        trigger.tap()

        let state = app.descendants(matching: .any)[IDs.clipboardStateLabel]
        XCTAssertTrue(state.waitForExistence(timeout: 1.5), "Clipboard state label should exist")
        XCTAssertEqual(state.xcuiAccessibleText, "Clipboard state: generated")
    }
}
