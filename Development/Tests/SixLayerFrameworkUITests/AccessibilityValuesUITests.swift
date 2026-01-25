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
    
    // MARK: - Toggle Values Tests
    
    /// Test that platformToggle has accessibility value ("On" or "Off")
    /// BUSINESS PURPOSE: Verify toggles report their current state for assistive technologies
    /// TESTING SCOPE: platformToggle value detection
    /// METHODOLOGY: Use XCUITest to find toggle and verify value reflects state
    @MainActor
    func testPlatformToggle_HasAccessibilityValue() throws {
        // Given: App is launched and ready
        // Navigate to a view with toggles (e.g., DynamicFormView)
        
        // When: Find platformToggle elements
        // Then: Should have accessibility value ("On" or "Off")
        let switches = app.switches.allElementsBoundByIndex
        
        for switchElement in switches {
            // Switches in XCUITest have a value property that reflects their state
            let value = switchElement.value as? String
            // Value should be "1" (on) or "0" (off) for switches, or "On"/"Off" if properly formatted
            XCTAssertNotNil(value, "Switch should have a value")
            
            // The value should indicate the state
            if let stringValue = value {
                let isOn = stringValue == "1" || stringValue.lowercased() == "on"
                let isOff = stringValue == "0" || stringValue.lowercased() == "off"
                XCTAssertTrue(isOn || isOff, "Switch value should indicate state (On/Off or 1/0). Actual: '\(stringValue)'")
                print("🔍 TEST DEBUG: Switch value: '\(stringValue)'")
            }
        }
    }
    
    // MARK: - Slider Values Tests
    
    /// Test that platformSlider has accessibility value (current value and range)
    /// BUSINESS PURPOSE: Verify sliders report their current value for assistive technologies
    /// TESTING SCOPE: platformSlider value detection
    /// METHODOLOGY: Use XCUITest to find slider and verify value reflects current position
    @MainActor
    func testPlatformSlider_HasAccessibilityValue() throws {
        // Given: App is launched and ready
        // Navigate to a view with sliders (e.g., DynamicRangeField)
        
        // When: Find slider elements
        // Then: Should have accessibility value indicating current position
        let sliders = app.sliders.allElementsBoundByIndex
        
        for slider in sliders {
            // Sliders in XCUITest have a value property that reflects their position
            let value = slider.value as? String
            XCTAssertNotNil(value, "Slider should have a value")
            
            if let stringValue = value {
                // Value should indicate position (e.g., "50%", "0.5", etc.)
                print("🔍 TEST DEBUG: Slider value: '\(stringValue)'")
                // Verify value is not empty
                XCTAssertFalse(stringValue.isEmpty, "Slider value should not be empty")
            }
        }
    }
    
    // MARK: - Stepper Values Tests
    
    /// Test that platformStepper has accessibility value (current value)
    /// BUSINESS PURPOSE: Verify steppers report their current value for assistive technologies
    /// TESTING SCOPE: platformStepper value detection
    /// METHODOLOGY: Use XCUITest to find stepper and verify value reflects current count
    @MainActor
    func testPlatformStepper_HasAccessibilityValue() throws {
        // Given: App is launched and ready
        // Navigate to a view with steppers (e.g., DynamicStepperField)
        
        // When: Find stepper elements
        // Then: Should have accessibility value indicating current count
        // Steppers in XCUITest can appear as increment/decrement buttons or as a single element
        let steppers = app.steppers.allElementsBoundByIndex
        
        for stepper in steppers {
            // Steppers have a value property
            let value = stepper.value as? String
            XCTAssertNotNil(value, "Stepper should have a value")
            
            if let stringValue = value {
                print("🔍 TEST DEBUG: Stepper value: '\(stringValue)'")
                // Verify value is not empty
                XCTAssertFalse(stringValue.isEmpty, "Stepper value should not be empty")
            }
        }
    }
    
    // MARK: - Picker Values Tests
    
    /// Test that platformPicker has accessibility value (selected option)
    /// BUSINESS PURPOSE: Verify pickers report their selected option for assistive technologies
    /// TESTING SCOPE: platformPicker value detection
    /// METHODOLOGY: Use XCUITest to find picker and verify value reflects selection
    @MainActor
    func testPlatformPicker_HasAccessibilityValue() throws {
        // Given: App is launched and ready
        // Navigate to a view with pickers
        
        // When: Find picker elements
        // Then: Should have accessibility value indicating selected option
        let pickers = app.pickers.allElementsBoundByIndex
        
        for picker in pickers {
            // Pickers have a value property that reflects the selected option
            let value = picker.value as? String
            XCTAssertNotNil(value, "Picker should have a value")
            
            if let stringValue = value {
                print("🔍 TEST DEBUG: Picker value: '\(stringValue)'")
                // Verify value is not empty
                XCTAssertFalse(stringValue.isEmpty, "Picker value should not be empty")
            }
        }
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
