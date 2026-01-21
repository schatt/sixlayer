//
//  AccessibilityRealUITests.swift
//  SixLayerFrameworkRealUITests
//
//  BUSINESS PURPOSE:
//  Real UI tests that verify accessibility identifiers are actually generated
//  and accessible when views are rendered in real windows. These tests use
//  XCUITest (XCUIApplication and XCUIElement) to verify that identifiers are
//  findable the same way production UI tests would find them.
//
//  TESTING SCOPE:
//  - Actual accessibility identifier generation in real app windows
//  - Modifier body execution in full app lifecycle
//  - Layout calculations that only happen in windows
//  - XCUITest element queries (same as production UI tests)
//
//  METHODOLOGY:
//  - Launch test app using XCUIApplication
//  - Wait for app to be ready
//  - Query elements using XCUIElement (same as production UI tests)
//  - Verify identifiers are findable using XCUITest APIs
//

import XCTest
@testable import SixLayerFramework

// Import XCUITestHelpers for performance optimizations
// Note: This file is in a different test target, so we'll duplicate the helpers here
// or access them if they're in a shared location
extension XCUIApplication {
    /// Wait for app to be ready before querying elements
    func waitForReady(timeout: TimeInterval = 5.0) -> Bool {
        return staticTexts["Test Content"].waitForExistence(timeout: timeout)
    }
    
    /// Launch app with performance optimizations
    func launchWithOptimizations() {
        launchArguments = ["-UITesting", "-SkipAnimations"]
        launchEnvironment = ["XCUI_TESTING": "1"]
        launch()
    }
}

/// Real UI tests for accessibility identifier generation using XCUITest
/// These tests use XCUIApplication and XCUIElement to verify identifiers are findable
final class AccessibilityRealUITests: XCTestCase {
    // XCUIApplication is thread-safe for the operations we perform
    nonisolated(unsafe) var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Launch the test app with performance optimizations (same as AccessibilityXCUITests)
        // XCTest runs on the main thread, so we can safely access main actor-isolated APIs
        // The property is marked nonisolated(unsafe) to allow access from nonisolated context
        app = XCUIApplication()
        app.launchWithOptimizations()
        
        // Wait for app to be ready before querying elements
        // This ensures SwiftUI has finished initial render and accessibility tree is built
        XCTAssertTrue(app.waitForReady(timeout: 5.0), "App should be ready for testing")
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// CONTROL TEST: Verify that XCUITest can find a standard SwiftUI button with direct .accessibilityIdentifier()
    /// This proves the testing infrastructure works before testing our modifier
    @MainActor
    func testControlDirectAccessibilityIdentifier() throws {
        // Given: App is launched and ready (from setUp)
        // The control button is always visible (not behind picker)
        // First verify the button exists by label (confirms app is working)
        let controlButtonByLabel = app.buttons["Control Button"]
        guard controlButtonByLabel.waitForExistence(timeout: 3.0) else {
            XCTFail("Control button should exist by label - app may not be fully loaded")
            return
        }
        
        // When: Query for element by accessibility identifier using XCUITest
        // This is a standard SwiftUI .accessibilityIdentifier() - no framework modifier
        // CRITICAL: We must find it by identifier, not by label
        let controlIdentifier = "control-test-button"
        
        // Try buttons first (since it's a Button)
        let buttonElement = app.buttons[controlIdentifier]
        if buttonElement.waitForExistence(timeout: 2.0) {
            // Found it by identifier! Control test passes - XCUITest infrastructure works
            // This proves XCUITest can find identifiers, so if our modifier fails, it's our bug
            return
        }
        
        // Try otherElements (sometimes identifiers are on otherElements)
        let otherElement = app.otherElements[controlIdentifier]
        if otherElement.waitForExistence(timeout: 0.5) {
            // Found it by identifier! Control test passes
            return
        }
        
        // If we get here, even the control test failed - XCUITest setup issue
        XCTFail("Control test failed: Standard SwiftUI .accessibilityIdentifier('\(controlIdentifier)') should be findable using XCUITest. This indicates an XCUITest infrastructure problem, not a framework bug.")
    }
    
    /// Test that accessibility identifiers are generated when view is rendered in a real window
    /// Uses XCUITest to find elements by accessibility identifier (same as production UI tests)
    @MainActor
    func testAccessibilityIdentifiersGeneratedInRealWindow() throws {
        // Given: App is launched and ready (from setUp)
        // The test app should have a Text view with automaticCompliance applied
        
        // First, verify the Text view itself exists (to confirm app is working)
        let textView = app.staticTexts["Test Content"]
        XCTAssertTrue(textView.waitForExistence(timeout: 2.0), "Text view should exist")
        
        // When: Query for element by accessibility identifier using XCUITest
        // This is the same way production UI tests would find elements
        let expectedIdentifier = "SixLayer.main.ui.element.View"
        
        // Try multiple query types to see if identifier is accessible
        let otherElement = app.otherElements[expectedIdentifier]
        let staticText = app.staticTexts[expectedIdentifier]
        let anyElement = app.descendants(matching: .any)[expectedIdentifier]
        
        // Then: Element should be findable using XCUITest
        // Try otherElements first (most common for accessibility identifiers)
        if otherElement.waitForExistence(timeout: 2.0) {
            // Found it!
            return
        }
        
        // Try staticTexts (in case identifier is on the Text view itself)
        if staticText.waitForExistence(timeout: 0.5) {
            // Found it!
            return
        }
        
        // Try any element
        if anyElement.waitForExistence(timeout: 0.5) {
            // Found it!
            return
        }
        
        // If we get here, identifier wasn't found - this is a bug in our code
        XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable using XCUITest. Tried otherElements, staticTexts, and any elements.")
    }
    
    /// Test that Button view generates accessibility identifier that XCUITest can find
    /// Uses XCUITest to find elements by accessibility identifier (same as production UI tests)
    @MainActor
    func testModifierBodyExecutesInRealWindow() throws {
        // Given: App is launched and ready (from setUp)
        // On macOS, a segmented picker exposes segments as buttons
        // The "Button" segment should be directly accessible as a button
        // Note: This test verifies our modifier works, but the picker interaction
        // is just a means to show the Button view - if the picker isn't accessible,
        // we can skip this test or make it conditional
        // Try to find the Button segment directly (segmented picker exposes segments as buttons)
        let buttonSegment = app.buttons["Button"]
        if buttonSegment.waitForExistence(timeout: 5.0) {
            // Found it! Select Button view type by tapping the segment
            buttonSegment.tap()
        } else {
            // If we can't find the Button segment directly, try the picker approach
            let picker = app.pickers.firstMatch
            if picker.waitForExistence(timeout: 2.0) {
                picker.tap()
                let buttonOption = app.buttons["Button"]
                guard buttonOption.waitForExistence(timeout: 2.0) else {
                    XCTFail("Button option should exist after tapping picker")
                    return
                }
                buttonOption.tap()
            } else {
                XCTFail("Cannot find Button segment or picker. Segmented picker may not be accessible on this platform.")
                return
            }
        }
        
        // Wait for the test button to appear (the button that's shown when Button is selected)
        let testButton = app.buttons["Test Button"]
        guard testButton.waitForExistence(timeout: 3.0) else {
            XCTFail("Test button should exist after selecting Button option")
            return
        }
        
        // When: Query for Button element by accessibility identifier using XCUITest
        // This is the same way production UI tests would find elements
        let expectedIdentifier = "SixLayer.main.ui.element.Button"
        
        // Try multiple query types
        let otherElement = app.otherElements[expectedIdentifier]
        if otherElement.waitForExistence(timeout: 2.0) {
            // Found it!
            return
        }
        
        let buttonElement = app.buttons[expectedIdentifier]
        if buttonElement.waitForExistence(timeout: 0.5) {
            // Found it!
            return
        }
        
        // If we get here, identifier wasn't found
        XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable using XCUITest. Tried otherElements and buttons.")
    }
}


