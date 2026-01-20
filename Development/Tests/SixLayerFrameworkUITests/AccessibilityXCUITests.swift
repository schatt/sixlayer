//
//  AccessibilityXCUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for accessibility identifier generation
//  These tests use XCUIApplication and XCUIElement to verify
//  that accessibility identifiers are actually usable by UI testing frameworks
//

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for accessibility identifier generation
/// These tests verify that identifiers are findable using XCUIElement queries,
/// which is how real UI tests would use them
final class AccessibilityXCUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Launch the test app
        app = XCUIApplication()
        app.launch()
        
        // Configure accessibility identifier generation
        // Note: This needs to be done in the app, not the test
        // We'll configure it in the app's onAppear
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// Test that Text view generates accessibility identifier that XCUITest can find
    func testTextAccessibilityIdentifierGenerated() throws {
        // Select Text view type in the picker
        let picker = app.pickers.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 2.0), "Picker should exist")
        
        // Ensure Text is selected (it's the default)
        if picker.value as? String != "Text" {
            picker.tap()
            app.buttons["Text"].tap()
        }
        
        // Wait for the view to appear
        let textView = app.staticTexts["Test Content"]
        XCTAssertTrue(textView.waitForExistence(timeout: 2.0), "Text view should exist")
        
        // Find element by accessibility identifier using XCUIElement query
        // This is the same way real UI tests would find elements
        let expectedIdentifier = "SixLayer.main.ui.element.View"
        let element = app.otherElements[expectedIdentifier]
        
        XCTAssertTrue(element.waitForExistence(timeout: 2.0), 
                     "Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest")
    }
    
    /// Test that Button view generates accessibility identifier that XCUITest can find
    func testButtonAccessibilityIdentifierGenerated() throws {
        // Select Button view type in the picker
        let picker = app.pickers.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 2.0), "Picker should exist")
        
        picker.tap()
        let buttonOption = app.buttons["Button"]
        XCTAssertTrue(buttonOption.waitForExistence(timeout: 2.0), "Button option should exist")
        buttonOption.tap()
        
        // Wait for the button to appear
        let testButton = app.buttons["Test Button"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 2.0), "Button should exist")
        
        // Find element by accessibility identifier using XCUIElement query
        // This is the same way real UI tests would find elements
        let expectedIdentifier = "SixLayer.main.ui.element.Button"
        let element = app.otherElements[expectedIdentifier]
        
        XCTAssertTrue(element.waitForExistence(timeout: 2.0), 
                     "Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest")
    }
}
