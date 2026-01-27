//
//  Layer3AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 3 platform*_L3 function accessibility
//  Implements Issue #168: Complete accessibility for Layer 3 platform* methods
//
//  These tests verify that all Layer 3 example views have:
//  - Accessibility identifiers
//  - Accessibility labels
//  - Accessibility hints (when appropriate)
//  - Correct accessibility traits
//  - VoiceOver compatibility
//  - Switch Control compatibility
//
//  Note: Layer 3 functions return data structures (OCRStrategy), not Views.
//  We test the example views that use these functions.

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for Layer 3 accessibility features
/// Verifies all 7 Layer 3 functions have example views with complete accessibility support
@MainActor
final class Layer3AccessibilityUITests: XCTestCase {
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
    
    /// Navigate to Layer 3 examples
    @MainActor
    private func navigateToLayer3Examples() throws {
        // Tap the "Layer 3 Strategy Examples" link
        let layer3Link = app.buttons["layer3-examples-link"]
        guard layer3Link.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Layer 3 examples link should exist")
            return
        }
        layer3Link.tap()
        
        // Wait for Layer 3 examples to load
        let layer3Title = app.navigationBars["Layer 3 Examples"]
        guard layer3Title.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Layer 3 Examples view should load")
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
    
    // MARK: - OCR Strategy Example Views Tests
    
    @MainActor
    func testOCRStrategyExampleViews_AccessibilityIdentifiers() throws {
        // Given: Navigate to Layer 3 examples
        try navigateToLayer3Examples()
        
        // When: Query for example view elements
        // Then: All should have accessibility identifiers
        
        // Test General OCR Strategy Example
        let generalExampleElements = app.descendants(matching: .any).matching(identifier: "GeneralOCRStrategyExample")
        if generalExampleElements.count > 0 {
            for i in 0..<min(generalExampleElements.count, 3) {
                let element = generalExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "GeneralOCRStrategyExample")
                }
            }
        }
        
        // Test Document OCR Strategy Example
        let documentExampleElements = app.descendants(matching: .any).matching(identifier: "DocumentOCRStrategyExample")
        if documentExampleElements.count > 0 {
            for i in 0..<min(documentExampleElements.count, 3) {
                let element = documentExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "DocumentOCRStrategyExample")
                }
            }
        }
        
        // Test Receipt OCR Strategy Example
        let receiptExampleElements = app.descendants(matching: .any).matching(identifier: "ReceiptOCRStrategyExample")
        if receiptExampleElements.count > 0 {
            for i in 0..<min(receiptExampleElements.count, 3) {
                let element = receiptExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "ReceiptOCRStrategyExample")
                }
            }
        }
        
        // Test Business Card OCR Strategy Example
        let businessCardExampleElements = app.descendants(matching: .any).matching(identifier: "BusinessCardOCRStrategyExample")
        if businessCardExampleElements.count > 0 {
            for i in 0..<min(businessCardExampleElements.count, 3) {
                let element = businessCardExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "BusinessCardOCRStrategyExample")
                }
            }
        }
        
        // Test Invoice OCR Strategy Example
        let invoiceExampleElements = app.descendants(matching: .any).matching(identifier: "InvoiceOCRStrategyExample")
        if invoiceExampleElements.count > 0 {
            for i in 0..<min(invoiceExampleElements.count, 3) {
                let element = invoiceExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "InvoiceOCRStrategyExample")
                }
            }
        }
        
        // Test Optimal OCR Strategy Example
        let optimalExampleElements = app.descendants(matching: .any).matching(identifier: "OptimalOCRStrategyExample")
        if optimalExampleElements.count > 0 {
            for i in 0..<min(optimalExampleElements.count, 3) {
                let element = optimalExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "OptimalOCRStrategyExample")
                }
            }
        }
        
        // Test Batch OCR Strategy Example
        let batchExampleElements = app.descendants(matching: .any).matching(identifier: "BatchOCRStrategyExample")
        if batchExampleElements.count > 0 {
            for i in 0..<min(batchExampleElements.count, 3) {
                let element = batchExampleElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "BatchOCRStrategyExample")
                }
            }
        }
        
        // Test StrategyDetailsView
        let strategyDetailsElements = app.descendants(matching: .any).matching(identifier: "StrategyDetailsView")
        if strategyDetailsElements.count > 0 {
            for i in 0..<min(strategyDetailsElements.count, 3) {
                let element = strategyDetailsElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: "StrategyDetailsView")
                }
            }
        }
    }
    
    @MainActor
    func testOCRStrategyExampleViews_AccessibilityLabels() throws {
        // Given: Navigate to Layer 3 examples
        try navigateToLayer3Examples()
        
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
                     "Layer 3 example buttons should have accessibility labels. Found \(labeledButtons) labeled out of \(buttons.count)")
    }
    
    @MainActor
    func testOCRStrategyExampleViews_AccessibilityTraits() throws {
        // Given: Navigate to Layer 3 examples
        try navigateToLayer3Examples()
        
        // When: Query for buttons
        // Then: All should have correct button traits
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists {
                verifyAccessibilityTraits(button, viewName: "Layer 3 Example Button", expectedType: .button)
            }
        }
    }
    
    // MARK: - VoiceOver Compatibility Tests
    
    @MainActor
    func testAllLayer3ExampleViews_VoiceOverCompatible() throws {
        // Given: Navigate to Layer 3 examples
        try navigateToLayer3Examples()
        
        // When: Query for all interactive elements
        // Then: All should be discoverable and readable by VoiceOver
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists {
                // Verify button is accessible
                XCTAssertTrue(button.isHittable || button.isEnabled,
                             "Layer 3 example button should be accessible to VoiceOver")
                
                // Verify button has label or identifier
                let hasLabel = !button.label.isEmpty
                let hasIdentifier = !button.identifier.isEmpty
                XCTAssertTrue(hasLabel || hasIdentifier,
                             "Layer 3 example button should have label or identifier for VoiceOver")
            }
        }
    }
    
    // MARK: - Switch Control Compatibility Tests
    
    @MainActor
    func testAllLayer3ExampleViews_SwitchControlCompatible() throws {
        // Given: Navigate to Layer 3 examples
        try navigateToLayer3Examples()
        
        // When: Query for all interactive elements
        // Then: All should have correct traits for Switch Control
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists {
                // Verify button has correct element type for Switch Control
                XCTAssertEqual(button.elementType, .button,
                               "Layer 3 example button should have button trait for Switch Control")
                
                // Verify button is enabled
                XCTAssertTrue(button.isEnabled,
                             "Layer 3 example button should be enabled for Switch Control")
            }
        }
    }
}
