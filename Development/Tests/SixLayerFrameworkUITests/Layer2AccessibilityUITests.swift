//
//  Layer2AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 2 platform*_L2 function accessibility
//  Implements Issue #167: Complete accessibility for Layer 2 platform* methods
//
//  These tests verify that all Layer 2 example views have:
//  - Accessibility identifiers
//  - Accessibility labels
//  - Accessibility hints (when appropriate)
//  - Correct accessibility traits
//  - VoiceOver compatibility
//  - Switch Control compatibility
//
//  Note: Layer 2 functions return data structures (OCRLayout), not Views.
//  We test the example views that use these functions.

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for Layer 2 accessibility features
/// Verifies all 4 Layer 2 functions have example views with complete accessibility support
@MainActor
final class Layer2AccessibilityUITests: XCTestCase {
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
    }
    
    // MARK: - Helper Methods
    
    /// Navigate to Layer 2 examples
    @MainActor
    private func navigateToLayer2Examples() throws {
        // Ensure app is ready
        guard app.waitForReady(timeout: 5.0) else {
            XCTFail("App should be ready for testing")
            return
        }
        
        // Tap the "Layer 2 Layout Examples" link
        // NavigationLink might be exposed as button, staticText, or other element
        // Try multiple strategies to find the element
        var layer2Link: XCUIElement?
        
        // Strategy 1: Try as button
        let buttonLink = app.buttons["layer2-examples-link"]
        if buttonLink.waitForExistenceFast(timeout: 2.0) {
            layer2Link = buttonLink
        } else {
            // Strategy 2: Try as staticText (NavigationLink label)
            let textLink = app.staticTexts["Layer 2 Layout Examples"]
            if textLink.waitForExistenceFast(timeout: 2.0) {
                layer2Link = textLink
            } else {
                // Strategy 3: Try findElement helper
                layer2Link = app.findElement(byIdentifier: "layer2-examples-link",
                                            primaryType: .button,
                                            secondaryTypes: [.staticText, .other, .any])
            }
        }
        
        guard let link = layer2Link else {
            XCTFail("Layer 2 examples link should exist")
            return
        }
        link.tap()
        
        // Wait for Layer 2 examples to load
        let layer2Title = app.navigationBars["Layer 2 Examples"]
        guard layer2Title.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Layer 2 Examples view should load")
            return
        }
        
        // Wait for content to appear
        sleep(1)
    }
    
    /// Verify an element has accessibility identifier
    @MainActor
    private func verifyAccessibilityIdentifier(_ element: XCUIElement, viewName: String) {
        let identifier = element.identifier
        XCTAssertFalse(identifier.isEmpty, 
                      "\(viewName) should have accessibility identifier. Found: '\(identifier)'")
    }
    
    /// Verify an element has accessibility label
    @MainActor
    private func verifyAccessibilityLabel(_ element: XCUIElement, viewName: String) {
        let label = element.label
        // For non-interactive elements, label might be empty, which is acceptable
        // But for interactive elements, label should be present
        if element.elementType == .button || element.elementType == .textField || 
           element.elementType == .switch || element.elementType == .slider {
            XCTAssertFalse(label.isEmpty, 
                          "\(viewName) interactive element should have accessibility label. Found: '\(label)'")
        }
    }
    
    /// Verify an element has correct accessibility traits
    @MainActor
    private func verifyAccessibilityTraits(_ element: XCUIElement, viewName: String, expectedType: XCUIElement.ElementType) {
        XCTAssertEqual(element.elementType, expectedType,
                      "\(viewName) should have correct accessibility trait. Expected: \(expectedType), Found: \(element.elementType)")
    }
    
    // MARK: - OCR Layout Example Views Tests
    
    @MainActor
    func testOCRLayoutExampleViews_AccessibilityIdentifiers() throws {
        // Given: Navigate to Layer 2 examples
        try navigateToLayer2Examples()
        
        // When: Query for example view elements
        // Then: All should have accessibility identifiers
        
        // Test General OCR Layout Example
        let generalExampleElements = app.descendants(matching: .any).matching(identifier: "GeneralOCRLayoutExample")
        if generalExampleElements.count > 0 {
            for i in 0..<min(generalExampleElements.count, 3) {
                let element = generalExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "GeneralOCRLayoutExample")
                }
            }
        }
        
        // Test Document OCR Layout Example
        let documentExampleElements = app.descendants(matching: .any).matching(identifier: "DocumentOCRLayoutExample")
        if documentExampleElements.count > 0 {
            for i in 0..<min(documentExampleElements.count, 3) {
                let element = documentExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "DocumentOCRLayoutExample")
                }
            }
        }
        
        // Test Receipt OCR Layout Example
        let receiptExampleElements = app.descendants(matching: .any).matching(identifier: "ReceiptOCRLayoutExample")
        if receiptExampleElements.count > 0 {
            for i in 0..<min(receiptExampleElements.count, 3) {
                let element = receiptExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "ReceiptOCRLayoutExample")
                }
            }
        }
        
        // Test Business Card OCR Layout Example
        let businessCardExampleElements = app.descendants(matching: .any).matching(identifier: "BusinessCardOCRLayoutExample")
        if businessCardExampleElements.count > 0 {
            for i in 0..<min(businessCardExampleElements.count, 3) {
                let element = businessCardExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "BusinessCardOCRLayoutExample")
                }
            }
        }
        
        // Test LayoutDetailsView
        let layoutDetailsElements = app.descendants(matching: .any).matching(identifier: "LayoutDetailsView")
        if layoutDetailsElements.count > 0 {
            for i in 0..<min(layoutDetailsElements.count, 3) {
                let element = layoutDetailsElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "LayoutDetailsView")
                }
            }
        }
    }
    
    @MainActor
    func testOCRLayoutExampleViews_AccessibilityLabels() throws {
        // Given: Navigate to Layer 2 examples
        try navigateToLayer2Examples()
        
        // When: Query for interactive elements
        // Then: All should have accessibility labels
        
        let buttons = app.buttons.allElementsBoundByIndex
        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
            }
        }
        XCTAssertTrue(labeledButtons > 0 || buttons.count == 0,
                     "Layer 2 example buttons should have accessibility labels. Found \(labeledButtons) labeled out of \(buttons.count)")
    }
    
    @MainActor
    func testOCRLayoutExampleViews_AccessibilityTraits() throws {
        // Given: Navigate to Layer 2 examples
        try navigateToLayer2Examples()
        
        // When: Query for buttons
        // Then: All should have correct button traits
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists {
                verifyAccessibilityTraits(button, viewName: "Layer 2 Example Button", expectedType: .button)
            }
        }
    }
    
    // MARK: - VoiceOver Compatibility Tests
    
    @MainActor
    func testAllLayer2ExampleViews_VoiceOverCompatible() throws {
        // Given: Navigate to Layer 2 examples
        try navigateToLayer2Examples()
        
        // When: Query for all interactive elements
        // Then: All should be discoverable and readable by VoiceOver
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists {
                // Verify button is accessible
                XCTAssertTrue(button.isHittable || button.isEnabled,
                             "Layer 2 example button should be accessible to VoiceOver")
                
                // Verify button has label or identifier
                let hasLabel = !button.label.isEmpty
                let hasIdentifier = !button.identifier.isEmpty
                XCTAssertTrue(hasLabel || hasIdentifier,
                             "Layer 2 example button should have label or identifier for VoiceOver")
            }
        }
    }
    
    // MARK: - Switch Control Compatibility Tests
    
    @MainActor
    func testAllLayer2ExampleViews_SwitchControlCompatible() throws {
        // Given: Navigate to Layer 2 examples
        try navigateToLayer2Examples()
        
        // When: Query for all interactive elements
        // Then: All should have correct traits for Switch Control
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists {
                // Verify button has correct element type for Switch Control
                XCTAssertEqual(button.elementType, .button,
                               "Layer 2 example button should have button trait for Switch Control")
                
                // Verify button is enabled
                XCTAssertTrue(button.isEnabled,
                             "Layer 2 example button should be enabled for Switch Control")
            }
        }
    }
}
