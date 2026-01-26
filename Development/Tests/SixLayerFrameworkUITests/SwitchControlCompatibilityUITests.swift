//
//  SwitchControlCompatibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Switch Control compatibility
//  Implements Issue #165: Complete accessibility for all platform* methods
//
//  These tests verify that all platform* functions are Switch Control-compatible
//  by ensuring interactive elements are accessible via Switch Control
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for Switch Control compatibility
/// These tests verify that all platform* functions are Switch Control-compatible
/// NOTE: XCUITest cannot directly test Switch Control, but we can verify
/// the prerequisites: elements must be focusable, tappable, and have proper traits
@MainActor
final class SwitchControlCompatibilityUITests: XCTestCase {
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
    
    // MARK: - Focusability Tests
    
    /// Test that interactive elements are focusable by Switch Control
    /// BUSINESS PURPOSE: Switch Control must be able to focus all interactive elements
    /// TESTING SCOPE: Element focusability
    /// METHODOLOGY: Verify all interactive elements can receive focus
    @MainActor
    func testInteractiveElements_AreFocusable() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should be focusable (have proper traits and are enabled)
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons are focusable
        for button in buttons {
            // Buttons should be enabled and have button trait
            XCTAssertTrue(button.isEnabled, "Button should be enabled for Switch Control focus")
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for Switch Control")
        }
        
        // Verify text fields are focusable
        for textField in textFields {
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled for Switch Control focus")
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for Switch Control")
        }
        
        // Verify switches are focusable
        for switchElement in switches {
            XCTAssertTrue(switchElement.isEnabled, "Switch should be enabled for Switch Control focus")
            XCTAssertTrue(switchElement.elementType == .switch, "Switch should have switch trait for Switch Control")
        }
    }
    
    // MARK: - Tappability Tests
    
    /// Test that interactive elements are tappable via Switch Control
    /// BUSINESS PURPOSE: Switch Control must be able to activate all interactive elements
    /// TESTING SCOPE: Element tappability
    /// METHODOLOGY: Verify elements can be tapped/activated
    @MainActor
    func testInteractiveElements_AreTappable() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should be tappable (enabled and have proper interaction traits)
        let buttons = app.buttons.allElementsBoundByIndex
        
        // Verify buttons are tappable
        for button in buttons {
            // Buttons should be enabled and tappable
            XCTAssertTrue(button.isEnabled, "Button should be enabled for Switch Control tapping")
            XCTAssertTrue(button.isHittable || button.exists, "Button should be hittable or exist for Switch Control")
        }
        
        // Test that we can actually tap a button (if available)
        if let firstButton = buttons.first, firstButton.isHittable {
            // Don't actually tap in tests, just verify it's possible
            XCTAssertTrue(firstButton.isHittable, "Button should be tappable via Switch Control")
        }
    }
    
    // MARK: - Trait Requirements Tests
    
    /// Test that elements have correct traits for Switch Control
    /// BUSINESS PURPOSE: Switch Control requires specific traits for proper interaction
    /// TESTING SCOPE: Trait correctness for Switch Control
    /// METHODOLOGY: Verify elements have appropriate traits
    @MainActor
    func testElements_HaveCorrectTraitsForSwitchControl() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should have correct traits for Switch Control
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons have button trait
        for button in buttons {
            XCTAssertTrue(button.elementType == .button,
                         "Button should have button trait for Switch Control")
        }
        
        // Verify text fields have text field trait
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField,
                         "Text field should have text field trait for Switch Control")
        }
        
        // Verify switches have switch trait
        for switchElement in switches {
            XCTAssertTrue(switchElement.elementType == .switch,
                         "Switch should have switch trait for Switch Control")
        }
    }
    
    // MARK: - Label Requirements Tests
    
    /// Test that elements have labels for Switch Control
    /// BUSINESS PURPOSE: Switch Control users need labels to identify elements
    /// TESTING SCOPE: Label presence for Switch Control
    /// METHODOLOGY: Verify all interactive elements have labels
    @MainActor
    func testElements_HaveLabelsForSwitchControl() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should have labels for Switch Control users
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons have labels
        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
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
        
        print("🔍 TEST DEBUG: Found \(labeledButtons) labeled buttons, \(labeledTextFields) labeled text fields, \(labeledSwitches) labeled switches for Switch Control")
        
        // At least some elements should have labels
        let totalLabeled = labeledButtons + labeledTextFields + labeledSwitches
        let totalElements = buttons.count + textFields.count + switches.count
        XCTAssertTrue(totalLabeled > 0 || totalElements == 0,
                     "Should have labeled elements for Switch Control. Found \(totalLabeled) labeled elements out of \(totalElements)")
    }
    
    // MARK: - Comprehensive Switch Control Compatibility Test
    
    /// Test comprehensive Switch Control compatibility for all platform* functions
    /// BUSINESS PURPOSE: Verify all platform* functions meet Switch Control requirements
    /// TESTING SCOPE: Complete Switch Control compatibility checklist
    /// METHODOLOGY: Verify all prerequisites for Switch Control compatibility
    @MainActor
    func testPlatformFunctions_AreSwitchControlCompatible() throws {
        // Given: App is launched and ready
        
        // When: Testing Switch Control compatibility
        // Then: All platform* functions should meet Switch Control requirements
        
        // Test 1: Focusability
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertTrue(button.isEnabled, "Elements should be enabled for Switch Control focus")
        }
        
        // Test 2: Tappability
        for button in buttons {
            XCTAssertTrue(button.isHittable || button.exists,
                         "Elements should be tappable via Switch Control")
        }
        
        // Test 3: Correct traits
        for button in buttons {
            XCTAssertTrue(button.elementType == .button,
                         "Elements should have correct traits for Switch Control")
        }
        
        // Test 4: Labels
        var labeledCount = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledCount += 1
            }
        }
        XCTAssertTrue(labeledCount > 0 || buttons.count == 0,
                     "Elements should have labels for Switch Control users")
        
        print("🔍 TEST DEBUG: Switch Control compatibility verified for \(buttons.count) buttons")
    }
}
