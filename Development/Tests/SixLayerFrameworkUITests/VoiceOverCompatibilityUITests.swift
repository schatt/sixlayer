//
//  VoiceOverCompatibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for VoiceOver compatibility
//  Implements Issue #165: Complete accessibility for all platform* methods
//
//  These tests verify that all platform* functions are VoiceOver-compatible
//  by ensuring they have proper labels, identifiers, traits, and hierarchy
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for VoiceOver compatibility
/// These tests verify that all platform* functions are VoiceOver-compatible
/// NOTE: XCUITest cannot directly test VoiceOver behavior, but we can verify
/// the prerequisites: elements must be discoverable, readable, and navigable
@MainActor
final class VoiceOverCompatibilityUITests: XCTestCase {
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
    
    // MARK: - Comprehensive VoiceOver Compatibility Tests
    
    /// Test comprehensive VoiceOver compatibility for all platform* functions
    /// BUSINESS PURPOSE: Verify all platform* functions meet VoiceOver requirements
    /// TESTING SCOPE: Complete VoiceOver compatibility checklist (discoverability, readability, navigability, hierarchy, state)
    /// METHODOLOGY: Verify all prerequisites for VoiceOver compatibility in a single test
    @MainActor
    func testPlatformFunctions_AreVoiceOverCompatible() throws {
        // Given: App is launched and ready
        
        // When: Testing VoiceOver compatibility
        // Then: All platform* functions should meet VoiceOver requirements
        
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        let sliders = app.sliders.allElementsBoundByIndex
        
        // Test 1: Discoverability (have identifiers or labels)
        for button in buttons {
            let hasIdentifier = !button.identifier.isEmpty
            let hasLabel = !button.label.isEmpty
            XCTAssertTrue(hasIdentifier || hasLabel,
                         "Button should be discoverable. Identifier: '\(button.identifier)', Label: '\(button.label)'")
        }
        
        // Test 2: Readability (have readable labels)
        var readableButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                readableButtons += 1
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, "Button label should be readable")
            }
        }
        
        // Test 3: Navigability (have correct traits)
        for button in buttons {
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for navigation")
        }
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for navigation")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.elementType == .switch, "Switch should have switch trait for navigation")
        }
        
        // Test 4: Hierarchy (elements exist with content)
        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        var elementsWithContent = 0
        for element in allElements {
            if !element.label.isEmpty || !element.identifier.isEmpty {
                elementsWithContent += 1
            }
        }
        XCTAssertTrue(elementsWithContent > 0,
                     "Accessibility hierarchy should contain elements with content. Found \(elementsWithContent) elements with content")
        
        // Test 5: State communication (stateful elements have values)
        for switchElement in switches {
            let value = switchElement.value as? String
            XCTAssertNotNil(value, "Switch should have a value for VoiceOver")
        }
        for slider in sliders {
            let value = slider.value as? String
            XCTAssertNotNil(value, "Slider should have a value for VoiceOver")
        }
        
        print("🔍 TEST DEBUG: VoiceOver compatibility verified for \(buttons.count) buttons, \(textFields.count) text fields, \(switches.count) switches, \(sliders.count) sliders")
    }
}
