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
        
        // Launch the test app with performance optimizations
        let (_, launchTime) = XCUITestPerformance.measure {
            app = XCUIApplication()
            app.launchWithOptimizations()
        }
        XCUITestPerformance.log("App launch", time: launchTime)
        
        // Wait for app to be ready before querying elements
        // This ensures SwiftUI has finished initial render and accessibility tree is built
        let (isReady, readyTime) = XCUITestPerformance.measure {
            XCTAssertTrue(app.waitForReady(timeout: 5.0), "App should be ready for testing")
        }
        XCUITestPerformance.log("App readiness check", time: readyTime)
        
        // Configure accessibility identifier generation
        // Note: This needs to be done in the app, not the test
        // We'll configure it in the app's onAppear
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// CONTROL TEST: Verify that XCUITest can find a standard SwiftUI button with direct .accessibilityIdentifier()
    /// This proves the testing infrastructure works before testing our modifier
    func testControlDirectAccessibilityIdentifier() throws {
        // Given: App is launched and ready (from setUp)
        // The control button is always visible (not behind picker)
        // First verify the button exists by label (confirms app is working)
        let controlButtonByLabel = app.buttons["Control Button"]
        guard controlButtonByLabel.existsImmediately || controlButtonByLabel.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Control button should exist by label - app may not be fully loaded")
            return
        }
        
        // When: Query for element by accessibility identifier using XCUITest
        // This is a standard SwiftUI .accessibilityIdentifier() - no framework modifier
        // CRITICAL: We must find it by identifier, not by label
        let controlIdentifier = "control-test-button"
        
        // Try buttons first (since it's a Button)
        let buttonElement = app.buttons[controlIdentifier]
        if buttonElement.existsImmediately || buttonElement.waitForExistenceFast(timeout: 2.0) {
            // Found it by identifier! Control test passes - XCUITest infrastructure works
            // This proves XCUITest can find identifiers, so if our modifier fails, it's our bug
            return
        }
        
        // Try otherElements (sometimes identifiers are on otherElements)
        let otherElement = app.otherElements[controlIdentifier]
        if otherElement.existsImmediately || otherElement.waitForExistenceFast(timeout: 0.5) {
            // Found it by identifier! Control test passes
            return
        }
        
        // If we get here, even the control test failed - XCUITest setup issue
        XCTFail("Control test failed: Standard SwiftUI .accessibilityIdentifier('\(controlIdentifier)') should be findable using XCUITest. This indicates an XCUITest infrastructure problem, not a framework bug.")
    }
    
    /// Test that Text view generates accessibility identifier that XCUITest can find
    func testTextAccessibilityIdentifierGenerated() throws {
        // App is already ready from setUp, so we can query elements immediately
        // On iOS, segmented picker exposes segments as buttons, not as a picker
        // Text is the default, so we can verify it's selected by checking the view exists
        // If we need to select it, we'd tap the "Text" button segment
        
        // Wait for the view to appear (should be immediate since Text is default)
        let textView = app.staticTexts["Test Content"]
        XCTAssertTrue(textView.existsImmediately || textView.waitForExistenceFast(timeout: 0.5), 
                     "Text view should exist immediately")
        
        // Find element by accessibility identifier using XCUIElement query
        // This is the same way real UI tests would find elements
        let expectedIdentifier = "SixLayer.main.ui.element.View"
        
        // Try multiple query types - identifiers can be on different element types
        let (otherElement, queryTime) = XCUITestPerformance.measure {
            app.otherElements[expectedIdentifier]
        }
        XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
        
        if otherElement.waitForExistenceFast(timeout: 1.0) {
            // Found it!
            return
        }
        
        // Try staticTexts (in case identifier is on the Text view itself)
        let staticTextElement = app.staticTexts[expectedIdentifier]
        if staticTextElement.waitForExistenceFast(timeout: 0.5) {
            // Found it!
            return
        }
        
        // Try any element
        let anyElement = app.descendants(matching: .any)[expectedIdentifier]
        if anyElement.waitForExistenceFast(timeout: 0.5) {
            // Found it!
            return
        }
        
        // If we get here, identifier wasn't found
        XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest. Tried otherElements, staticTexts, and any elements.")
    }
    
    /// Test that Button view generates accessibility identifier that XCUITest can find
    func testButtonAccessibilityIdentifierGenerated() throws {
        // App is already ready from setUp, so we can query elements immediately
        // On iOS, segmented picker exposes segments as buttons directly
        // Find and tap the "Button" segment
        let buttonSegment = app.buttons["Button"]
        XCTAssertTrue(buttonSegment.existsImmediately || buttonSegment.waitForExistenceFast(timeout: 1.0), 
                     "Button segment should exist in segmented control")
        
        // Select Button view type by tapping the segment
        buttonSegment.tap()
        
        // Wait for the button to appear (may need slightly longer timeout after interaction)
        let testButton = app.buttons["Test Button"]
        XCTAssertTrue(testButton.waitForExistenceFast(timeout: 1.0), "Button should exist after selection")
        
        // Find element by accessibility identifier using XCUIElement query
        // This is the same way real UI tests would find elements
        let expectedIdentifier = "SixLayer.main.ui.element.Button"
        
        // Try multiple query types - identifiers can be on different element types
        let (otherElement, queryTime) = XCUITestPerformance.measure {
            app.otherElements[expectedIdentifier]
        }
        XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
        
        if otherElement.waitForExistenceFast(timeout: 1.0) {
            // Found it!
            return
        }
        
        // Try buttons (in case identifier is on the Button view itself)
        let buttonElement = app.buttons[expectedIdentifier]
        if buttonElement.waitForExistenceFast(timeout: 0.5) {
            // Found it!
            return
        }
        
        // Try any element
        let anyElement = app.descendants(matching: .any)[expectedIdentifier]
        if anyElement.waitForExistenceFast(timeout: 0.5) {
            // Found it!
            return
        }
        
        // If we get here, identifier wasn't found
        XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest. Tried otherElements, buttons, and any elements.")
    }
}
