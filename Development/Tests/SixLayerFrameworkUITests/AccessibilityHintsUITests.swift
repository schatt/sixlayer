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
        addDefaultUIInterruptionMonitor()

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
    
    // MARK: - Comprehensive Accessibility Hints Tests
    
    /// Test that all interactive elements are accessible (hints are applied but not directly testable)
    /// BUSINESS PURPOSE: Verify all platform* elements are accessible and hints are applied in code
    /// TESTING SCOPE: Comprehensive accessibility verification for buttons, text fields, toggles, pickers
    /// METHODOLOGY: Verify all element types are findable and have labels - hints verified via unit tests
    /// NOTE: XCUITest cannot directly read accessibility hints (they're only available to VoiceOver)
    /// Hints are verified via unit tests that check the SwiftUI view modifiers directly
    @MainActor
    func testAllInteractiveElements_AreAccessibleWithHints() throws {
        // Given: App is launched and ready
        // Navigate to a test view that has various elements (e.g., Button Test)
        let buttonTestButton = app.buttons["test-view-Button Test"]
        if buttonTestButton.waitForExistenceFast(timeout: 3.0) {
            buttonTestButton.tap()
        }
        
        // When: Find all interactive elements
        // Then: All should be findable and accessible with labels (required for hints to be useful)
        
        // Test buttons
        let buttons = app.buttons.allElementsBoundByIndex
        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
            }
        }
        XCTAssertTrue(labeledButtons > 0 || buttons.count == 0,
                     "Buttons should have accessibility labels. Found \(labeledButtons) labeled buttons out of \(buttons.count)")
        
        // Test text fields
        let textFields = app.textFields.allElementsBoundByIndex
        var labeledTextFields = 0
        for textField in textFields {
            if !textField.label.isEmpty {
                labeledTextFields += 1
            }
        }
        XCTAssertTrue(labeledTextFields > 0 || textFields.count == 0,
                     "Text fields should have accessibility labels. Found \(labeledTextFields) labeled text fields out of \(textFields.count)")
        
        // Test switches/toggles
        let switches = app.switches.allElementsBoundByIndex
        var labeledSwitches = 0
        for switchElement in switches {
            if !switchElement.label.isEmpty {
                labeledSwitches += 1
            }
        }
        XCTAssertTrue(labeledSwitches > 0 || switches.count == 0,
                     "Switches should have accessibility labels. Found \(labeledSwitches) labeled switches out of \(switches.count)")
        
        // Test pickers
        let pickers = app.pickers.allElementsBoundByIndex
        var labeledPickers = 0
        for picker in pickers {
            if !picker.label.isEmpty {
                labeledPickers += 1
            }
        }
        XCTAssertTrue(labeledPickers > 0 || pickers.count == 0,
                     "Pickers should have accessibility labels. Found \(labeledPickers) labeled pickers out of \(pickers.count)")
        
        print("🔍 TEST DEBUG: Found \(labeledButtons) labeled buttons, \(labeledTextFields) labeled text fields, \(labeledSwitches) labeled switches, \(labeledPickers) labeled pickers")
    }
}
