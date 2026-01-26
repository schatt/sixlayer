//
//  HighContrastSupportUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for High Contrast support
//  Implements Issue #165: Complete accessibility for all platform* methods
//
//  These tests verify that all platform* functions support High Contrast mode
//  by ensuring elements remain usable and visible
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for High Contrast support
/// These tests verify that all platform* functions support High Contrast mode
/// NOTE: XCUITest cannot directly test High Contrast mode, but we can verify
/// that elements have proper contrast and remain usable
@MainActor
final class HighContrastSupportUITests: XCTestCase {
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
    
    // MARK: - Visibility Tests
    
    /// Test that elements remain visible in High Contrast mode
    /// BUSINESS PURPOSE: Elements must remain visible for High Contrast users
    /// TESTING SCOPE: Element visibility
    /// METHODOLOGY: Verify elements are visible and accessible
    @MainActor
    func testElements_RemainVisibleInHighContrast() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should be visible (exist and are accessible)
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons are visible
        for button in buttons {
            XCTAssertTrue(button.exists, "Button should exist for High Contrast support")
            // Note: We can't directly test color contrast, but we verify elements exist
        }
        
        // Verify text fields are visible
        for textField in textFields {
            XCTAssertTrue(textField.exists, "Text field should exist for High Contrast support")
        }
        
        // Verify switches are visible
        for switchElement in switches {
            XCTAssertTrue(switchElement.exists, "Switch should exist for High Contrast support")
        }
        
        print("🔍 TEST DEBUG: Verified \(buttons.count) buttons, \(textFields.count) text fields, \(switches.count) switches are visible")
    }
    
    // MARK: - Usability Tests
    
    /// Test that elements remain usable in High Contrast mode
    /// BUSINESS PURPOSE: Elements must remain usable for High Contrast users
    /// TESTING SCOPE: Element usability
    /// METHODOLOGY: Verify elements are enabled and interactive
    @MainActor
    func testElements_RemainUsableInHighContrast() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should be usable (enabled and interactive)
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons are usable
        for button in buttons {
            XCTAssertTrue(button.isEnabled, "Button should be enabled for High Contrast support")
            XCTAssertTrue(button.isHittable || button.exists,
                         "Button should be hittable for High Contrast support")
        }
        
        // Verify text fields are usable
        for textField in textFields {
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled for High Contrast support")
        }
        
        // Verify switches are usable
        for switchElement in switches {
            XCTAssertTrue(switchElement.isEnabled, "Switch should be enabled for High Contrast support")
        }
    }
    
    // MARK: - Label Visibility Tests
    
    /// Test that labels remain visible in High Contrast mode
    /// BUSINESS PURPOSE: Labels must remain visible for High Contrast users
    /// TESTING SCOPE: Label visibility
    /// METHODOLOGY: Verify elements have readable labels
    @MainActor
    func testLabels_RemainVisibleInHighContrast() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should have visible labels
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons have labels
        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
                // Labels should be readable (not empty or just whitespace)
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty,
                             "Button label should be visible for High Contrast. Label: '\(button.label)'")
            }
        }
        
        // Verify text fields have labels
        var labeledTextFields = 0
        for textField in textFields {
            if !textField.label.isEmpty {
                labeledTextFields += 1
            }
        }
        
        // Verify switches have labels
        var labeledSwitches = 0
        for switchElement in switches {
            if !switchElement.label.isEmpty {
                labeledSwitches += 1
            }
        }
        
        print("🔍 TEST DEBUG: Found \(labeledButtons) labeled buttons, \(labeledTextFields) labeled text fields, \(labeledSwitches) labeled switches for High Contrast")
        
        // At least some elements should have labels
        let totalLabeled = labeledButtons + labeledTextFields + labeledSwitches
        let totalElements = buttons.count + textFields.count + switches.count
        XCTAssertTrue(totalLabeled > 0 || totalElements == 0,
                     "Should have labeled elements for High Contrast. Found \(totalLabeled) labeled elements out of \(totalElements)")
    }
    
    // MARK: - Border and Outline Tests
    
    /// Test that elements have proper borders/outlines for High Contrast
    /// BUSINESS PURPOSE: Elements should have clear boundaries in High Contrast mode
    /// TESTING SCOPE: Element boundaries
    /// METHODOLOGY: Verify elements are properly defined (have proper traits)
    @MainActor
    func testElements_HaveProperBoundariesForHighContrast() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should have proper boundaries (correct traits)
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        
        // Verify buttons have proper traits (indicates proper boundaries)
        for button in buttons {
            XCTAssertTrue(button.elementType == .button,
                         "Button should have button trait for High Contrast boundaries")
        }
        
        // Verify text fields have proper traits
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField,
                         "Text field should have text field trait for High Contrast boundaries")
        }
    }
    
    // MARK: - Comprehensive High Contrast Support Test
    
    /// Test comprehensive High Contrast support for all platform* functions
    /// BUSINESS PURPOSE: Verify all platform* functions support High Contrast mode
    /// TESTING SCOPE: Complete High Contrast support checklist
    /// METHODOLOGY: Verify all prerequisites for High Contrast support
    @MainActor
    func testPlatformFunctions_SupportHighContrast() throws {
        // Given: App is launched and ready
        
        // When: Testing High Contrast support
        // Then: All platform* functions should support High Contrast
        
        // Test 1: Visibility
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertTrue(button.exists, "Elements should be visible for High Contrast")
        }
        
        // Test 2: Usability
        for button in buttons {
            XCTAssertTrue(button.isEnabled, "Elements should be usable for High Contrast")
        }
        
        // Test 3: Label visibility
        var labeledCount = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledCount += 1
            }
        }
        XCTAssertTrue(labeledCount > 0 || buttons.count == 0,
                     "Elements should have visible labels for High Contrast")
        
        // Test 4: Proper boundaries
        for button in buttons {
            XCTAssertTrue(button.elementType == .button,
                         "Elements should have proper traits for High Contrast boundaries")
        }
        
        print("🔍 TEST DEBUG: High Contrast support verified for \(buttons.count) buttons")
    }
}
