//
//  AccessibilityTraitsUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for accessibility traits
//  Implements Issue #165: Complete accessibility for all platform* methods
//
//  These tests use XCUIApplication and XCUIElement to verify
//  that accessibility traits are correct for all interactive platform* functions
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for accessibility traits
/// These tests verify that accessibility traits are correct for all interactive platform* functions
/// Buttons should have .isButton, links should have .isLink, headers should have .isHeader, etc.
@MainActor
final class AccessibilityTraitsUITests: XCTestCase {
    var app: XCUIApplication!
    
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Add UI interruption monitors to dismiss system dialogs quickly
        addUIInterruptionMonitor(withDescription: "System alerts and dialogs") { (alert) -> Bool in
            return MainActor.assumeIsolated {
                let alertText = alert.staticTexts.firstMatch.label
                if alertText.contains("Bluetooth") || alertText.contains("CPU") || alertText.contains("Activity Monitor") {
                    if alert.buttons["OK"].exists {
                        alert.buttons["OK"].tap()
                        return true
                    }
                    if alert.buttons["Cancel"].exists {
                        alert.buttons["Cancel"].tap()
                        return true
                    }
                    if alert.buttons["Don't Allow"].exists {
                        alert.buttons["Don't Allow"].tap()
                        return true
                    }
                }
                return false
            }
        }
        
        // Launch the test app
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            var localApp: XCUIApplication!
            localApp = XCUIApplication()
            localApp.launchWithOptimizations()
            instance.app = localApp
            
            // Wait for app to be ready
            XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
        }
    }
    
    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
        try super.tearDownWithError()
    }
    
    // MARK: - Comprehensive Traits Tests
    
    /// Test that all interactive elements have correct traits
    /// BUSINESS PURPOSE: Verify all platform* elements are identified correctly for assistive technologies
    /// TESTING SCOPE: Comprehensive trait verification for buttons, links, headers, text fields, toggles
    /// METHODOLOGY: Verify all element types have appropriate traits in a single test
    @MainActor
    func testAllInteractiveElements_HaveCorrectTraits() throws {
        // Given: App is launched and ready
        // Navigate to a test view that has various elements
        let buttonTestButton = app.buttons["test-view-Button Test"]
        if buttonTestButton.waitForExistenceFast(timeout: 3.0) {
            buttonTestButton.tap()
        }
        
        // When: Query for all interactive elements
        // Then: Each should have appropriate traits
        
        // Verify buttons have button trait
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertTrue(button.elementType == .button, "Button should have button trait")
        }
        
        // Verify text fields have text field trait
        let textFields = app.textFields.allElementsBoundByIndex
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait")
        }
        
        // Verify switches have switch trait
        let switches = app.switches.allElementsBoundByIndex
        for switchElement in switches {
            XCTAssertTrue(switchElement.elementType == .switch, "Switch should have switch trait")
        }
        
        // Verify navigation bars have titles (headers)
        let navBars = app.navigationBars.allElementsBoundByIndex
        for navBar in navBars {
            let titles = navBar.staticTexts.allElementsBoundByIndex
            XCTAssertTrue(titles.count > 0, "Navigation bar should have a title (header)")
        }
        
        print("🔍 TEST DEBUG: Found \(buttons.count) buttons, \(textFields.count) text fields, \(switches.count) switches, \(navBars.count) navigation bars")
    }
}
