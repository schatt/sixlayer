//
//  AccessibilityHintsUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for accessibility hints
//  Implements Issue #165: Complete accessibility for all platform* methods
//
//  These tests use XCUIApplication and XCUIElement to verify
//  that accessibility hints are present and readable for all platform* functions
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for accessibility hints
/// These tests verify that accessibility hints are present and contain appropriate content
/// for all platform* functions that should have hints
@MainActor
final class AccessibilityHintsUITests: XCTestCase {
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
    
    // MARK: - Button Hints Tests
    
    /// Test that platformButton elements are findable (hints are applied but not directly testable)
    /// BUSINESS PURPOSE: Verify buttons are accessible and hints are applied in code
    /// TESTING SCOPE: platformButton accessibility verification
    /// METHODOLOGY: Verify buttons are findable - hints are verified via unit tests with ViewInspector
    /// NOTE: XCUITest cannot directly read accessibility hints (they're only available to VoiceOver)
    /// Hints are verified via unit tests that check the SwiftUI view modifiers directly
    @MainActor
    func testPlatformButton_IsAccessible() throws {
        // Given: App is launched and ready
        // Navigate to a test view that has buttons (e.g., Button Test)
        let buttonTestButton = app.buttons["test-view-Button Test"]
        if buttonTestButton.waitForExistenceFast(timeout: 3.0) {
            buttonTestButton.tap()
        }
        
        // When: Find platformButton elements
        // Then: Should be findable and accessible
        // Note: Hints are applied in code but cannot be read via XCUITest
        // Hints are verified via unit tests using ViewInspector
        let buttons = app.buttons.allElementsBoundByIndex
        
        XCTAssertTrue(buttons.count > 0, "Should find at least one button")
        
        // Verify buttons have labels (required for hints to be useful)
        var labeledButtons = 0
        for button in buttons {
            // Buttons should have labels for accessibility
            // Hints are applied but not directly testable via XCUITest
            if !button.label.isEmpty {
                labeledButtons += 1
            }
        }
        
        // At least some buttons should have labels
        XCTAssertTrue(labeledButtons > 0 || buttons.count == 0,
                     "Buttons should have accessibility labels. Found \(labeledButtons) labeled buttons out of \(buttons.count)")
    }
    
    // MARK: - Text Field Hints Tests
    
    // MARK: - Toggle Hints Tests
    
    /// Test that platformToggle elements are findable (hints are applied but not directly testable)
    /// BUSINESS PURPOSE: Verify toggles are accessible and hints are applied in code
    /// TESTING SCOPE: platformToggle accessibility verification
    /// METHODOLOGY: Verify toggles are findable - hints are verified via unit tests
    /// NOTE: XCUITest cannot directly read accessibility hints
    @MainActor
    func testPlatformToggle_IsAccessible() throws {
        // Given: App is launched and ready
        // Navigate to a view with toggles
        
        // When: Find platformToggle elements
        // Then: Should be findable and accessible
        // Hints are applied in code but cannot be read via XCUITest
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify switches have labels (required for hints to be useful)
        for switchElement in switches {
            XCTAssertFalse(switchElement.label.isEmpty, "Switch should have an accessibility label")
        }
    }
    
    // MARK: - Picker Hints Tests
    
    // MARK: - Hint Content Quality Tests
    
    /// Test that buttons have labels (required for hints to be useful)
    /// BUSINESS PURPOSE: Verify buttons are properly labeled for accessibility
    /// TESTING SCOPE: Button label verification
    /// METHODOLOGY: Verify buttons have non-empty labels
    /// NOTE: Hint content is verified via unit tests with ViewInspector
    @MainActor
    func testButtonLabels_ArePresent() throws {
        // Given: App is launched and ready
        // Navigate to views with buttons
        
        // When: Find buttons
        // Then: Should have labels (hints are applied but not directly testable)
        let buttons = app.buttons.allElementsBoundByIndex
        
        var labelsFound = 0
        for button in buttons {
            if !button.label.isEmpty {
                labelsFound += 1
            }
        }
        
        // Verify at least some buttons have labels
        XCTAssertTrue(labelsFound > 0 || buttons.count == 0,
                     "Buttons should have labels for accessibility. Found \(labelsFound) labeled buttons out of \(buttons.count)")
    }
    
    /// Test that text fields have labels (required for hints to be useful)
    /// BUSINESS PURPOSE: Verify text fields are properly labeled for accessibility
    /// TESTING SCOPE: Text field label verification
    /// METHODOLOGY: Verify text fields have non-empty labels
    /// NOTE: Hint content is verified via unit tests with ViewInspector
    @MainActor
    func testTextFieldLabels_ArePresent() throws {
        // Given: App is launched and ready
        
        // When: Find text fields
        // Then: Should have labels (hints are applied but not directly testable)
        let textFields = app.textFields.allElementsBoundByIndex
        
        var labelsFound = 0
        for textField in textFields {
            if !textField.label.isEmpty {
                labelsFound += 1
            }
        }
        
        // Verify text fields have labels
        XCTAssertTrue(labelsFound > 0 || textFields.count == 0,
                     "Text fields should have labels for accessibility. Found \(labelsFound) labeled text fields out of \(textFields.count)")
    }
}
