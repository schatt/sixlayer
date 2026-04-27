//
//  PlatformToolbarAccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  Issue #221: optional accessibilityIdentifier on platformFormToolbar / platformDetailToolbar.
//  XCUITest is the authoritative layer — ViewInspector does not reliably expose these toolbar IDs on macOS.
//
//  Form and detail use separate launch arguments so macOS does not depend on popping NavigationLink
//  (back affordance is inconsistent under XCUI).
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

        let testName = name
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            if testName.contains("testIssue221_platformFormToolbar") {
                localApp.launchArguments.append("-OpenPlatformToolbarIssue221Form")
            } else if testName.contains("testIssue221_platformDetailToolbar") {
                localApp.launchArguments.append("-OpenPlatformToolbarIssue221Detail")
            } else {
                XCTFail("Add launch arg mapping for \(testName)")
                return
            }
            localApp.launch()
            instance.app = localApp

            if testName.contains("testIssue221_platformFormToolbar") {
                XCTAssertTrue(
                    localApp.staticTexts["Form toolbar host"].waitForExistence(timeout: 2.0),
                    "Form host should appear (-OpenPlatformToolbarIssue221Form)"
                )
            } else {
                XCTAssertTrue(
                    localApp.staticTexts["Detail toolbar host"].waitForExistence(timeout: 2.0),
                    "Detail host should appear (-OpenPlatformToolbarIssue221Detail)"
                )
            }
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
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
            timeout: 2.0
        )
        XCTAssertNotNil(
            found,
            "Expected an element with accessibility identifier '\(identifier)' in the XCUI hierarchy",
            file: file,
            line: line
        )
    }

    func testIssue221_platformFormToolbar_optionalIds_queryableViaXCUITest() throws {
        #if os(iOS) || os(macOS)
        assertIdentifierQueryable(IDs.formCancel)
        assertIdentifierQueryable(IDs.formSave)
        #if os(macOS)
        assertIdentifierQueryable(IDs.formSelect)
        #endif
        #else
        throw XCTSkip("Issue #221 toolbar UI tests require iOS or macOS TestApp")
        #endif
    }

    func testIssue221_platformDetailToolbar_optionalIds_queryableViaXCUITest() throws {
        #if os(iOS) || os(macOS)
        assertIdentifierQueryable(IDs.detailCancel)
        assertIdentifierQueryable(IDs.detailSave)
        #else
        throw XCTSkip("Issue #221 toolbar UI tests require iOS or macOS TestApp")
        #endif
    }
}
