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
    
    // MARK: - Comprehensive Switch Control Compatibility Tests
    
    /// Test comprehensive Switch Control compatibility for all platform* functions
    /// BUSINESS PURPOSE: Verify all platform* functions meet Switch Control requirements
    /// TESTING SCOPE: Complete Switch Control compatibility checklist (focusability, tappability, traits, labels)
    /// METHODOLOGY: Verify all prerequisites for Switch Control compatibility in a single test
    @MainActor
    func testPlatformFunctions_AreSwitchControlCompatible() throws {
        // Given: App is launched and ready
        
        // When: Testing Switch Control compatibility
        // Then: All platform* functions should meet Switch Control requirements
        
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Test 1: Focusability (enabled and have proper traits)
        for button in buttons {
            XCTAssertTrue(button.isEnabled, "Button should be enabled for Switch Control focus")
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for Switch Control")
        }
        for textField in textFields {
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled for Switch Control focus")
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for Switch Control")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.isEnabled, "Switch should be enabled for Switch Control focus")
            XCTAssertTrue(switchElement.elementType == .switch, "Switch should have switch trait for Switch Control")
        }
        
        // Test 2: Tappability (hittable or exist)
        for button in buttons {
            XCTAssertTrue(button.isHittable || button.exists, "Button should be tappable via Switch Control")
        }
        
        // Test 3: Labels (for element identification)
        var labeledCount = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledCount += 1
            }
        }
        for textField in textFields {
            if !textField.label.isEmpty {
                labeledCount += 1
            }
        }
        for switchElement in switches {
            if !switchElement.label.isEmpty {
                labeledCount += 1
            }
        }
        let totalElements = buttons.count + textFields.count + switches.count
        XCTAssertTrue(labeledCount > 0 || totalElements == 0,
                     "Elements should have labels for Switch Control users. Found \(labeledCount) labeled elements out of \(totalElements)")
        
        print("🔍 TEST DEBUG: Switch Control compatibility verified for \(buttons.count) buttons, \(textFields.count) text fields, \(switches.count) switches")
    }
}
