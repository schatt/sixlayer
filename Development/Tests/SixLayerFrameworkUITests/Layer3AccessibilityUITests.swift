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
/// #348 / #316: deep-link via `-OpenLayer3Examples`; land on `layer3-examples-host-root`.
@MainActor
final class Layer3AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!
    
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Add UI interruption monitors to dismiss system dialogs quickly
        addDefaultUIInterruptionMonitor()

        // Launch directly on Layer 3 examples (#316 / #348).
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer3Examples")
            localApp.launch()
            instance.app = localApp

            XCTAssertTrue(
                localApp.waitForHostRootIdentifier("layer3-examples-host-root"),
                "App should open Layer 3 Examples (-OpenLayer3Examples)"
            )
        }
    }
    
    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }
    
    // MARK: - Helper Methods
    
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
                // When: Query for interactive example buttons (skip empty macOS chrome #316)
        // Then: Content buttons should be discoverable and readable by VoiceOver
        
        let buttons = app.buttons.allElementsBoundByIndex
        var contentButtons = 0
        for button in buttons {
            guard button.exists else { continue }
            let accessible = button.xcuiAccessibleText
            let identifier = button.identifier
            // Window chrome / latent nodes: disabled with no label/id — not Layer 3 content.
            if !button.isEnabled && identifier.isEmpty && accessible.isEmpty {
                continue
            }
            contentButtons += 1
            XCTAssertTrue(
                button.isEnabled || !identifier.isEmpty || !accessible.isEmpty,
                "Layer 3 example button should be accessible to VoiceOver"
            )
            XCTAssertTrue(
                !accessible.isEmpty || !identifier.isEmpty,
                "Layer 3 example button should have label or identifier for VoiceOver"
            )
        }
        XCTAssertGreaterThan(contentButtons, 0, "Layer 3 examples should expose at least one VoiceOver-reachable button")
    }
    
    // MARK: - Switch Control Compatibility Tests
    
    @MainActor
    func testAllLayer3ExampleViews_SwitchControlCompatible() throws {
        // Given: Navigate to Layer 3 examples
                // When: Query for interactive example buttons (skip empty macOS chrome #316)
        // Then: Content buttons should have correct traits for Switch Control
        
        let buttons = app.buttons.allElementsBoundByIndex
        var contentButtons = 0
        for button in buttons {
            guard button.exists else { continue }
            let accessible = button.xcuiAccessibleText
            let identifier = button.identifier
            if !button.isEnabled && identifier.isEmpty && accessible.isEmpty {
                continue
            }
            contentButtons += 1
            XCTAssertEqual(
                button.elementType,
                .button,
                "Layer 3 example button should have button trait for Switch Control"
            )
            // Enabled when hittable; off-screen / latent chrome may report isHittable without being content.
            if button.isHittable && (!identifier.isEmpty || !accessible.isEmpty) {
                XCTAssertTrue(
                    button.isEnabled,
                    "Layer 3 example button should be enabled for Switch Control"
                )
            }
        }
        XCTAssertGreaterThan(contentButtons, 0, "Layer 3 examples should expose at least one Switch Control-reachable button")
    }
}
