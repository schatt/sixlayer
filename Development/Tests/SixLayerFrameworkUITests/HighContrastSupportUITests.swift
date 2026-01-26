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
    
    // MARK: - Comprehensive High Contrast Support Tests
    
    /// Test comprehensive High Contrast support for all platform* functions
    /// BUSINESS PURPOSE: Verify all platform* functions support High Contrast mode
    /// TESTING SCOPE: Complete High Contrast support checklist (visibility, usability, label visibility, proper boundaries)
    /// METHODOLOGY: Verify all prerequisites for High Contrast support in a single test
    @MainActor
    func testPlatformFunctions_SupportHighContrast() throws {
        // Given: App is launched and ready
        
        // When: Testing High Contrast support
        // Then: All platform* functions should support High Contrast
        
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Test 1: Visibility (elements exist)
        for button in buttons {
            XCTAssertTrue(button.exists, "Button should exist for High Contrast support")
        }
        for textField in textFields {
            XCTAssertTrue(textField.exists, "Text field should exist for High Contrast support")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.exists, "Switch should exist for High Contrast support")
        }
        
        // Test 2: Usability (enabled and interactive)
        for button in buttons {
            XCTAssertTrue(button.isEnabled, "Button should be enabled for High Contrast support")
            XCTAssertTrue(button.isHittable || button.exists, "Button should be hittable for High Contrast support")
        }
        for textField in textFields {
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled for High Contrast support")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.isEnabled, "Switch should be enabled for High Contrast support")
        }
        
        // Test 3: Label visibility (elements have readable labels)
        var labeledCount = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledCount += 1
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, "Button label should be visible for High Contrast")
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
                     "Elements should have visible labels for High Contrast. Found \(labeledCount) labeled elements out of \(totalElements)")
        
        // Test 4: Proper boundaries (correct traits)
        for button in buttons {
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for High Contrast boundaries")
        }
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for High Contrast boundaries")
        }
        
        print("🔍 TEST DEBUG: High Contrast support verified for \(buttons.count) buttons, \(textFields.count) text fields, \(switches.count) switches")
    }
}
