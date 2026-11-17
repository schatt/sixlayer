//
//  DisplayOCRTrainingAppUITests.swift
//  DisplayOCRTrainingUITests
//
//  The training app's window is the display trainer (#609).
//

import XCTest

#if os(iOS) || os(macOS)
@MainActor
final class DisplayOCRTrainingAppUITests: XCTestCase {
    func testTrainingScreenIsTheWindow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Display training"].waitForExistence(timeout: 10),
            "The training app should open on the display training screen"
        )
        XCTAssertTrue(
            app.staticTexts["Load a pump or display photo."].waitForExistence(timeout: 10),
            "The training app should show the empty trainer, not a shell"
        )
    }
}
#endif
