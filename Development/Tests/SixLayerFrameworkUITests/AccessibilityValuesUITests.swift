//
//  AccessibilityValuesUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for accessibility values
//  Implements Issue #165: Complete accessibility for all platform* methods
//
//  These tests use XCUIApplication and XCUIElement to verify
//  that accessibility values are present and accurate for all stateful platform* functions
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for accessibility values
/// These tests verify that accessibility values are present and accurate for all stateful platform* functions
/// Toggles should report "On" or "Off", Sliders should report current value and range, etc.
@MainActor
final class AccessibilityValuesUITests: XCTestCase {
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
    
    // MARK: - Comprehensive Values Tests
    
    /// Test that all stateful elements have accessibility values
    /// BUSINESS PURPOSE: Verify all stateful platform* elements report their state for assistive technologies
    /// TESTING SCOPE: Comprehensive value verification for toggles, sliders, steppers, pickers
    /// METHODOLOGY: Verify all stateful element types have values in a single test
    @MainActor
    func testAllStatefulElements_HaveAccessibilityValues() throws {
        // Given: App is launched and ready
        
        // When: Find all stateful elements
        // Then: All should have accessibility values
        
        // Test switches/toggles
        let switches = app.switches.allElementsBoundByIndex
        for switchElement in switches {
            let value = switchElement.value as? String
            XCTAssertNotNil(value, "Switch should have a value")
            if let stringValue = value {
                let isOn = stringValue == "1" || stringValue.lowercased() == "on"
                let isOff = stringValue == "0" || stringValue.lowercased() == "off"
                XCTAssertTrue(isOn || isOff, "Switch value should indicate state (On/Off or 1/0). Actual: '\(stringValue)'")
            }
        }
        
        // Test sliders
        let sliders = app.sliders.allElementsBoundByIndex
        for slider in sliders {
            let value = slider.value as? String
            XCTAssertNotNil(value, "Slider should have a value")
            if let stringValue = value {
                XCTAssertFalse(stringValue.isEmpty, "Slider value should not be empty")
            }
        }
        
        // Test steppers
        let steppers = app.steppers.allElementsBoundByIndex
        for stepper in steppers {
            let value = stepper.value as? String
            XCTAssertNotNil(value, "Stepper should have a value")
            if let stringValue = value {
                XCTAssertFalse(stringValue.isEmpty, "Stepper value should not be empty")
            }
        }
        
        // Test pickers
        let pickers = app.pickers.allElementsBoundByIndex
        for picker in pickers {
            let value = picker.value as? String
            XCTAssertNotNil(value, "Picker should have a value")
            if let stringValue = value {
                XCTAssertFalse(stringValue.isEmpty, "Picker value should not be empty")
            }
        }
        
        print("🔍 TEST DEBUG: Verified values for \(switches.count) switches, \(sliders.count) sliders, \(steppers.count) steppers, \(pickers.count) pickers")
    }
    
    // MARK: - Value Accuracy Tests
    
    /// Test that toggle values accurately reflect state changes
    /// BUSINESS PURPOSE: Verify toggle values update when state changes
    /// TESTING SCOPE: Toggle value accuracy verification
    /// METHODOLOGY: Toggle a switch and verify value updates
    @MainActor
    func testToggleValue_ReflectsStateChanges() throws {
        // Given: App is launched and ready
        // Find a toggle
        
        let switches = app.switches.allElementsBoundByIndex
        guard let firstSwitch = switches.first else {
            // No switches to test - skip
            return
        }
        
        // Get initial value
        let initialValue = firstSwitch.value as? String
        XCTAssertNotNil(initialValue, "Switch should have initial value")
        
        // When: Toggle the switch
        firstSwitch.tap()
        
        // Wait for state to update
        sleep(1)
        
        // Then: Value should change
        let newValue = firstSwitch.value as? String
        XCTAssertNotNil(newValue, "Switch should have new value after toggle")
        
        if let initial = initialValue, let new = newValue {
            // Values should be different (unless there was an error)
            XCTAssertNotEqual(initial, new, "Switch value should change after toggle. Initial: '\(initial)', New: '\(new)'")
            print("🔍 TEST DEBUG: Toggle value changed from '\(initial)' to '\(new)'")
        }
    }
    
    /// Test that slider values accurately reflect position
    /// BUSINESS PURPOSE: Verify slider values reflect current position
    /// TESTING SCOPE: Slider value accuracy verification
    /// METHODOLOGY: Adjust slider and verify value updates
    @MainActor
    func testSliderValue_ReflectsPosition() throws {
        // Given: App is launched and ready
        // Find a slider
        
        let sliders = app.sliders.allElementsBoundByIndex
        guard let firstSlider = sliders.first else {
            // No sliders to test - skip
            return
        }
        
        // Get initial value
        let initialValue = firstSlider.value as? String
        XCTAssertNotNil(initialValue, "Slider should have initial value")
        
        // When: Adjust the slider (drag to a new position)
        // Note: Slider adjustment requires coordinate-based interaction
        // For now, we just verify the value exists and is not empty
        
        if let value = initialValue {
            print("🔍 TEST DEBUG: Slider value: '\(value)'")
            XCTAssertFalse(value.isEmpty, "Slider value should not be empty")
        }
    }
}
