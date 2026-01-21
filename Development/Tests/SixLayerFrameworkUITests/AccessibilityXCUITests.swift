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
        let (element, queryTime) = XCUITestPerformance.measure {
            app.otherElements[expectedIdentifier]
        }
        XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
        
        // Use shorter timeout since app is ready and identifier should be set
        XCTAssertTrue(element.waitForExistenceFast(timeout: 1.0), 
                     "Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest")
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
        let (element, queryTime) = XCUITestPerformance.measure {
            app.otherElements[expectedIdentifier]
        }
        XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
        
        // Use shorter timeout since app is ready and identifier should be set
        XCTAssertTrue(element.waitForExistenceFast(timeout: 1.0), 
                     "Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest")
    }
}
