//
//  PlatformToolbarAccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #221: optional accessibilityIdentifier on platformFormToolbar / platformDetailToolbar.
//  XCUITest is the authoritative layer — ViewInspector does not reliably expose these toolbar IDs on macOS.
//

import XCTest

@MainActor
final class PlatformToolbarAccessibilityUITests: XCTestCase {
    private enum IDs {
        static let formSave = "SixLayer.tests.platformFormToolbar.save.221"
        static let formCancel = "SixLayer.tests.platformFormToolbar.cancel.221"
        static let formSelect = "SixLayer.tests.platformFormToolbar.select.221"
        static let detailSave = "SixLayer.tests.platformDetailToolbar.save.221"
        static let detailCancel = "SixLayer.tests.platformDetailToolbar.cancel.221"
    }

    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenPlatformToolbarIssue221")
            localApp.launch()
            instance.app = localApp

            let hubVisible = localApp.staticTexts["Toolbar Issue 221"].waitForExistence(timeout: 5.0)
                || localApp.navigationBars["Toolbar Issue 221"].waitForExistence(timeout: 2.0)
            XCTAssertTrue(hubVisible, "Hub should appear (-OpenPlatformToolbarIssue221)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    /// Taps a hub row exposed as link, button, or static text (SwiftUI List variance across platforms).
    private func tapHubRow(labeled title: String) {
        let candidates: [XCUIElement] = [
            app.links[title].firstMatch,
            app.buttons[title].firstMatch,
            app.staticTexts[title].firstMatch,
        ]
        for element in candidates {
            if element.waitForExistence(timeout: 1.2), element.isHittable {
                element.tap()
                return
            }
        }
        XCTFail("Could not tap hub row titled '\(title)'")
    }

    private func popDetailNavigation() {
        #if os(macOS)
        // macOS SwiftUI: back affordance varies (hub title, chevron, or keyboard only).
        let candidates: [XCUIElement] = [
            app.navigationBars.buttons["Toolbar Issue 221"].firstMatch,
            app.navigationBars.buttons.firstMatch,
            app.buttons["Toolbar Issue 221"].firstMatch,
            app.links["Toolbar Issue 221"].firstMatch,
        ]
        for element in candidates {
            if element.waitForExistence(timeout: 1.5), element.isHittable {
                element.tap()
                break
            }
        }
        if !(app.staticTexts["Toolbar Issue 221"].waitForExistence(timeout: 0.8)
            || app.navigationBars["Toolbar Issue 221"].waitForExistence(timeout: 0.8)) {
            app.typeKey("[", modifierFlags: .command)
        }
        #else
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 3.0), "Expected navigation bar back control")
        back.tap()
        #endif
        XCTAssertTrue(
            app.staticTexts["Toolbar Issue 221"].waitForExistence(timeout: 4.0)
                || app.navigationBars["Toolbar Issue 221"].waitForExistence(timeout: 3.0),
            "Expected return to hub after pop"
        )
    }

    private func assertIdentifierQueryable(
        _ identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let found = app.findElement(
            byIdentifier: identifier,
            primaryType: .button,
            secondaryTypes: [.staticText, .cell, .other, .any],
            timeout: 6.0
        )
        XCTAssertNotNil(
            found,
            "Expected an element with accessibility identifier '\(identifier)' in the XCUI hierarchy",
            file: file,
            line: line
        )
    }

    func testIssue221_platformFormAndDetailToolbar_optionalIds_queryableViaXCUITest() throws {
        #if os(iOS) || os(macOS)
        tapHubRow(labeled: "Form toolbar")
        XCTAssertTrue(
            app.staticTexts["Form toolbar host"].waitForExistence(timeout: 5.0),
            "Form host content should appear"
        )

        assertIdentifierQueryable(IDs.formCancel)
        assertIdentifierQueryable(IDs.formSave)
        #if os(macOS)
        assertIdentifierQueryable(IDs.formSelect)
        #endif

        popDetailNavigation()

        tapHubRow(labeled: "Detail toolbar")
        XCTAssertTrue(
            app.staticTexts["Detail toolbar host"].waitForExistence(timeout: 5.0),
            "Detail host content should appear"
        )

        assertIdentifierQueryable(IDs.detailCancel)
        assertIdentifierQueryable(IDs.detailSave)
        #else
        throw XCTSkip("Issue #221 toolbar UI tests require iOS or macOS TestApp")
        #endif
    }
}
