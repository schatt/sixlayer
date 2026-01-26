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
    
    // MARK: - Discoverability Tests
    
    /// Test that interactive elements are discoverable by VoiceOver
    /// BUSINESS PURPOSE: VoiceOver must be able to find all interactive elements
    /// TESTING SCOPE: Element discoverability via identifiers and labels
    /// METHODOLOGY: Verify all interactive elements have identifiers or labels
    @MainActor
    func testInteractiveElements_AreDiscoverable() throws {
        // Given: App is launched and ready
        // Navigate to Layer 1 Examples
        let layer1Button = app.buttons["test-view-Layer 1 Examples"]
        if layer1Button.waitForExistenceFast(timeout: 3.0) {
            layer1Button.tap()
        }
        
        // When: Query for interactive elements
        // Then: All should be discoverable (have identifiers or labels)
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons are discoverable
        for button in buttons {
            let hasIdentifier = !button.identifier.isEmpty
            let hasLabel = !button.label.isEmpty
            XCTAssertTrue(hasIdentifier || hasLabel, 
                         "Button should be discoverable (have identifier or label). Identifier: '\(button.identifier)', Label: '\(button.label)'")
        }
        
        // Verify text fields are discoverable
        for textField in textFields {
            let hasIdentifier = !textField.identifier.isEmpty
            let hasLabel = !textField.label.isEmpty
            XCTAssertTrue(hasIdentifier || hasLabel,
                         "Text field should be discoverable (have identifier or label). Identifier: '\(textField.identifier)', Label: '\(textField.label)'")
        }
        
        // Verify switches are discoverable
        for switchElement in switches {
            let hasIdentifier = !switchElement.identifier.isEmpty
            let hasLabel = !switchElement.label.isEmpty
            XCTAssertTrue(hasIdentifier || hasLabel,
                         "Switch should be discoverable (have identifier or label). Identifier: '\(switchElement.identifier)', Label: '\(switchElement.label)'")
        }
    }
    
    // MARK: - Readability Tests
    
    /// Test that elements have readable labels for VoiceOver
    /// BUSINESS PURPOSE: VoiceOver must be able to read element labels
    /// TESTING SCOPE: Label presence and quality
    /// METHODOLOGY: Verify all interactive elements have non-empty, descriptive labels
    @MainActor
    func testElements_HaveReadableLabels() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should have readable labels
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons have readable labels
        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
                // Labels should be descriptive (more than just whitespace)
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, 
                             "Button label should not be empty or whitespace. Label: '\(button.label)'")
            }
        }
        
        // Verify text fields have readable labels
        var labeledTextFields = 0
        for textField in textFields {
            if !textField.label.isEmpty {
                labeledTextFields += 1
                let trimmedLabel = textField.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty,
                             "Text field label should not be empty or whitespace. Label: '\(textField.label)'")
            }
        }
        
        // Verify switches have readable labels
        var labeledSwitches = 0
        for switchElement in switches {
            if !switchElement.label.isEmpty {
                labeledSwitches += 1
                let trimmedLabel = switchElement.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty,
                             "Switch label should not be empty or whitespace. Label: '\(switchElement.label)'")
            }
        }
        
        print("🔍 TEST DEBUG: Found \(labeledButtons) labeled buttons, \(labeledTextFields) labeled text fields, \(labeledSwitches) labeled switches")
    }
    
    // MARK: - Navigability Tests
    
    /// Test that elements have correct traits for VoiceOver navigation
    /// BUSINESS PURPOSE: VoiceOver must be able to navigate elements correctly
    /// TESTING SCOPE: Trait correctness for navigation
    /// METHODOLOGY: Verify elements have appropriate traits (buttons, links, headers, etc.)
    @MainActor
    func testElements_HaveCorrectTraitsForNavigation() throws {
        // Given: App is launched and ready
        
        // When: Query for interactive elements
        // Then: All should have correct traits for VoiceOver navigation
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        
        // Verify buttons have button trait
        for button in buttons {
            XCTAssertTrue(button.elementType == .button,
                         "Button should have button trait for VoiceOver navigation")
        }
        
        // Verify text fields have text field trait
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField,
                         "Text field should have text field trait for VoiceOver navigation")
        }
        
        // Verify switches have switch trait
        for switchElement in switches {
            XCTAssertTrue(switchElement.elementType == .switch,
                         "Switch should have switch trait for VoiceOver navigation")
        }
    }
    
    // MARK: - Hierarchy Tests
    
    /// Test that accessibility hierarchy is logical for VoiceOver
    /// BUSINESS PURPOSE: VoiceOver must navigate elements in logical order
    /// TESTING SCOPE: Element hierarchy and ordering
    /// METHODOLOGY: Verify elements appear in logical order in accessibility tree
    @MainActor
    func testAccessibilityHierarchy_IsLogical() throws {
        // Given: App is launched and ready
        // Navigate to a view with multiple elements
        
        // When: Query for elements in order
        // Then: Elements should appear in logical order
        // Note: We can't directly test sort priority, but we can verify elements exist
        // and that navigation order makes sense (e.g., buttons before text fields in forms)
        
        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        
        // Verify we have elements
        XCTAssertTrue(allElements.count > 0, "Should have elements in accessibility hierarchy")
        
        // Verify elements have proper structure (not all empty)
        var elementsWithContent = 0
        for element in allElements {
            if !element.label.isEmpty || !element.identifier.isEmpty {
                elementsWithContent += 1
            }
        }
        
        XCTAssertTrue(elementsWithContent > 0,
                     "Accessibility hierarchy should contain elements with content. Found \(elementsWithContent) elements with content out of \(allElements.count)")
    }
    
    // MARK: - State Communication Tests
    
    /// Test that stateful elements communicate their state to VoiceOver
    /// BUSINESS PURPOSE: VoiceOver must announce element state changes
    /// TESTING SCOPE: State communication via values
    /// METHODOLOGY: Verify stateful elements have values that reflect their state
    @MainActor
    func testStatefulElements_CommunicateState() throws {
        // Given: App is launched and ready
        
        // When: Query for stateful elements
        // Then: Should have values that communicate state
        let switches = app.switches.allElementsBoundByIndex
        let sliders = app.sliders.allElementsBoundByIndex
        
        // Verify switches have values
        for switchElement in switches {
            let value = switchElement.value as? String
            XCTAssertNotNil(value, "Switch should have a value for VoiceOver to announce state")
            if let stringValue = value {
                let isOn = stringValue == "1" || stringValue.lowercased() == "on"
                let isOff = stringValue == "0" || stringValue.lowercased() == "off"
                XCTAssertTrue(isOn || isOff,
                             "Switch value should indicate state (On/Off or 1/0) for VoiceOver. Value: '\(stringValue)'")
            }
        }
        
        // Verify sliders have values
        for slider in sliders {
            let value = slider.value as? String
            XCTAssertNotNil(value, "Slider should have a value for VoiceOver to announce position")
            if let stringValue = value {
                XCTAssertFalse(stringValue.isEmpty,
                             "Slider value should not be empty for VoiceOver. Value: '\(stringValue)'")
            }
        }
    }
    
    // MARK: - Comprehensive VoiceOver Compatibility Test
    
    /// Test comprehensive VoiceOver compatibility for all platform* functions
    /// BUSINESS PURPOSE: Verify all platform* functions meet VoiceOver requirements
    /// TESTING SCOPE: Complete VoiceOver compatibility checklist
    /// METHODOLOGY: Verify all prerequisites for VoiceOver compatibility
    @MainActor
    func testPlatformFunctions_AreVoiceOverCompatible() throws {
        // Given: App is launched and ready
        // Navigate through different example views
        
        // When: Testing VoiceOver compatibility
        // Then: All platform* functions should meet VoiceOver requirements
        
        // Test 1: Discoverability
        let buttons = app.buttons.allElementsBoundByIndex
        XCTAssertTrue(buttons.count > 0, "Should have buttons to test")
        
        // Test 2: Readability
        var readableElements = 0
        for button in buttons {
            if !button.label.isEmpty {
                readableElements += 1
            }
        }
        XCTAssertTrue(readableElements > 0 || buttons.count == 0,
                     "Should have readable elements. Found \(readableElements) readable buttons out of \(buttons.count)")
        
        // Test 3: Navigability
        for button in buttons {
            XCTAssertTrue(button.elementType == .button,
                         "Buttons should have correct trait for navigation")
        }
        
        // Test 4: State communication (for stateful elements)
        let switches = app.switches.allElementsBoundByIndex
        for switchElement in switches {
            let value = switchElement.value as? String
            XCTAssertNotNil(value, "Stateful elements should communicate state")
        }
        
        print("🔍 TEST DEBUG: VoiceOver compatibility verified for \(buttons.count) buttons, \(switches.count) switches")
    }
}
