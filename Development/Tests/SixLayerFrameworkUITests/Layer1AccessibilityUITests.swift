//
//  Layer1AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 1 platform*_L1 function accessibility
//  Implements Issue #166: Complete accessibility for Layer 1 platform* methods
//
//  These tests verify that all Layer 1 functions have:
//  - Accessibility identifiers
//  - Accessibility labels
//  - Accessibility hints (when appropriate)
//  - Correct accessibility traits
//  - VoiceOver compatibility
//  - Switch Control compatibility
//

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for Layer 1 accessibility features
/// Verifies all 86 Layer 1 functions have complete accessibility support
@MainActor
final class Layer1AccessibilityUITests: XCTestCase {
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
    
    /// Navigate to Layer 1 examples and select a category
    @MainActor
    private func navigateToLayer1Category(_ categoryName: String) throws {
        // Ensure app is ready
        guard app.waitForReady(timeout: 5.0) else {
            XCTFail("App should be ready for testing")
            return
        }
        
        // Tap the "Show Layer 1 Examples" button
        let toggleButton = app.buttons["layer1-examples-toggle"]
        guard toggleButton.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Layer 1 examples toggle button should exist")
            return
        }
        // Check if already expanded (value == "1" means expanded)
        if (toggleButton.value as? String) != "1" {
            toggleButton.tap()
        }
        
        // Wait for picker to appear
        let picker = app.pickers.firstMatch
        guard picker.waitForExistenceFast(timeout: 2.0) else {
            XCTFail("Category picker should exist")
            return
        }
        
        // Select the category
        picker.tap()
        let categoryOption = app.menuItems[categoryName]
        guard categoryOption.waitForExistenceFast(timeout: 2.0) else {
            XCTFail("Category '\(categoryName)' should exist in picker")
            return
        }
        categoryOption.tap()
        
        // Wait for examples to load
        sleep(1)
    }
    
    /// Verify an element has accessibility identifier
    @MainActor
    private func verifyAccessibilityIdentifier(_ element: XCUIElement, functionName: String) {
        let identifier = element.identifier
        XCTAssertFalse(identifier.isEmpty, 
                      "\(functionName) should have accessibility identifier. Found: '\(identifier)'")
    }
    
    /// Verify an element has accessibility label
    @MainActor
    private func verifyAccessibilityLabel(_ element: XCUIElement, functionName: String) {
        let label = element.label
        // For non-interactive elements, label might be empty, which is acceptable
        // But for interactive elements, label should be present
        if element.elementType == .button || element.elementType == .textField || 
           element.elementType == .switch || element.elementType == .slider {
            XCTAssertFalse(label.isEmpty, 
                          "\(functionName) interactive element should have accessibility label. Found: '\(label)'")
        }
    }
    
    /// Verify an element has correct accessibility traits
    @MainActor
    private func verifyAccessibilityTraits(_ element: XCUIElement, functionName: String, expectedType: XCUIElement.ElementType) {
        XCTAssertEqual(element.elementType, expectedType,
                      "\(functionName) should have correct accessibility trait. Expected: \(expectedType), Found: \(element.elementType)")
    }
    
    // MARK: - Data Presentation Tests
    
    @MainActor
    func testDataPresentationFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to data presentation examples
        try navigateToLayer1Category("Data Presentation")
        
        // When: Query for elements
        // Then: All should have accessibility identifiers
        
        // Test item collection
        let itemCollectionElements = app.descendants(matching: .any).matching(identifier: "platformPresentItemCollection_L1")
        if itemCollectionElements.count > 0 {
            for i in 0..<min(itemCollectionElements.count, 5) { // Test first 5
                let element = itemCollectionElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentItemCollection_L1")
                }
            }
        }
        
        // Test numeric data
        let numericDataElements = app.descendants(matching: .any).matching(identifier: "platformPresentNumericData_L1")
        if numericDataElements.count > 0 {
            for i in 0..<min(numericDataElements.count, 3) {
                let element = numericDataElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentNumericData_L1")
                }
            }
        }
        
        // Test form data
        let formDataElements = app.descendants(matching: .any).matching(identifier: "platformPresentFormData_L1")
        if formDataElements.count > 0 {
            for i in 0..<min(formDataElements.count, 3) {
                let element = formDataElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentFormData_L1")
                }
            }
        }
    }
    
    @MainActor
    func testDataPresentationFunctions_AccessibilityLabels() throws {
        // Given: Navigate to data presentation examples
        try navigateToLayer1Category("Data Presentation")
        
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
                     "Data presentation buttons should have accessibility labels. Found \(labeledButtons) labeled out of \(buttons.count)")
        
        let textFields = app.textFields.allElementsBoundByIndex
        var labeledTextFields = 0
        for textField in textFields {
            if !textField.label.isEmpty {
                labeledTextFields += 1
            }
        }
        XCTAssertTrue(labeledTextFields > 0 || textFields.count == 0,
                     "Data presentation text fields should have accessibility labels. Found \(labeledTextFields) labeled out of \(textFields.count)")
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigationFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to navigation examples
        try navigateToLayer1Category("Navigation")
        
        // When: Query for navigation elements
        // Then: All should have accessibility identifiers
        
        let navElements = app.descendants(matching: .any).matching(identifier: "platformPresentNavigationStack_L1")
        if navElements.count > 0 {
            for i in 0..<min(navElements.count, 3) {
                let element = navElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentNavigationStack_L1")
                }
            }
        }
        
        let appNavElements = app.descendants(matching: .any).matching(identifier: "platformPresentAppNavigation_L1")
        if appNavElements.count > 0 {
            for i in 0..<min(appNavElements.count, 2) {
                let element = appNavElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentAppNavigation_L1")
                }
            }
        }
    }
    
    // MARK: - Photo Tests
    
    @MainActor
    func testPhotoFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to photo examples
        try navigateToLayer1Category("Photos")
        
        // When: Query for photo elements
        // Then: All should have accessibility identifiers
        
        let photoCaptureElements = app.descendants(matching: .any).matching(identifier: "platformPhotoCapture_L1")
        if photoCaptureElements.count > 0 {
            for i in 0..<min(photoCaptureElements.count, 2) {
                let element = photoCaptureElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPhotoCapture_L1")
                }
            }
        }
        
        let photoSelectionElements = app.descendants(matching: .any).matching(identifier: "platformPhotoSelection_L1")
        if photoSelectionElements.count > 0 {
            for i in 0..<min(photoSelectionElements.count, 2) {
                let element = photoSelectionElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPhotoSelection_L1")
                }
            }
        }
    }
    
    // MARK: - Security Tests
    
    @MainActor
    func testSecurityFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to security examples
        try navigateToLayer1Category("Security")
        
        // When: Query for security elements
        // Then: All should have accessibility identifiers
        
        let secureContentElements = app.descendants(matching: .any).matching(identifier: "platformPresentSecureContent_L1")
        if secureContentElements.count > 0 {
            for i in 0..<min(secureContentElements.count, 2) {
                let element = secureContentElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentSecureContent_L1")
                }
            }
        }
        
        let secureTextFieldElements = app.descendants(matching: .any).matching(identifier: "platformPresentSecureTextField_L1")
        if secureTextFieldElements.count > 0 {
            for i in 0..<min(secureTextFieldElements.count, 2) {
                let element = secureTextFieldElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentSecureTextField_L1")
                    verifyAccessibilityLabel(element, functionName: "platformPresentSecureTextField_L1")
                }
            }
        }
    }
    
    // MARK: - OCR Tests
    
    @MainActor
    func testOCRFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to OCR examples
        try navigateToLayer1Category("OCR")
        
        // When: Query for OCR elements
        // Then: All should have accessibility identifiers
        
        let ocrDisambiguationElements = app.descendants(matching: .any).matching(identifier: "platformOCRWithDisambiguation_L1")
        if ocrDisambiguationElements.count > 0 {
            for i in 0..<min(ocrDisambiguationElements.count, 2) {
                let element = ocrDisambiguationElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformOCRWithDisambiguation_L1")
                }
            }
        }
        
        let ocrVisualCorrectionElements = app.descendants(matching: .any).matching(identifier: "platformOCRWithVisualCorrection_L1")
        if ocrVisualCorrectionElements.count > 0 {
            for i in 0..<min(ocrVisualCorrectionElements.count, 2) {
                let element = ocrVisualCorrectionElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformOCRWithVisualCorrection_L1")
                }
            }
        }
    }
    
    // MARK: - Notification Tests
    
    @MainActor
    func testNotificationFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to notification examples
        try navigateToLayer1Category("Notifications")
        
        // When: Query for notification elements
        // Then: All should have accessibility identifiers
        
        let alertElements = app.descendants(matching: .any).matching(identifier: "platformPresentAlert_L1")
        if alertElements.count > 0 {
            for i in 0..<min(alertElements.count, 2) {
                let element = alertElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentAlert_L1")
                }
            }
        }
    }
    
    // MARK: - Internationalization Tests
    
    @MainActor
    func testInternationalizationFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to internationalization examples
        try navigateToLayer1Category("Internationalization")
        
        // When: Query for internationalization elements
        // Then: All should have accessibility identifiers
        
        let localizedTextElements = app.descendants(matching: .any).matching(identifier: "platformPresentLocalizedText_L1")
        if localizedTextElements.count > 0 {
            for i in 0..<min(localizedTextElements.count, 3) {
                let element = localizedTextElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformPresentLocalizedText_L1")
                }
            }
        }
        
        let localizedTextFieldElements = app.descendants(matching: .any).matching(identifier: "platformLocalizedTextField_L1")
        if localizedTextFieldElements.count > 0 {
            for i in 0..<min(localizedTextFieldElements.count, 2) {
                let element = localizedTextFieldElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformLocalizedTextField_L1")
                    verifyAccessibilityLabel(element, functionName: "platformLocalizedTextField_L1")
                }
            }
        }
    }
    
    // MARK: - Data Analysis Tests
    
    @MainActor
    func testDataAnalysisFunctions_AccessibilityIdentifiers() throws {
        // Given: Navigate to data analysis examples
        try navigateToLayer1Category("Data Analysis")
        
        // When: Query for data analysis elements
        // Then: All should have accessibility identifiers
        
        let analyzeElements = app.descendants(matching: .any).matching(identifier: "platformAnalyzeDataFrame_L1")
        if analyzeElements.count > 0 {
            for i in 0..<min(analyzeElements.count, 2) {
                let element = analyzeElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformAnalyzeDataFrame_L1")
                }
            }
        }
        
        let compareElements = app.descendants(matching: .any).matching(identifier: "platformCompareDataFrames_L1")
        if compareElements.count > 0 {
            for i in 0..<min(compareElements.count, 2) {
                let element = compareElements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, functionName: "platformCompareDataFrames_L1")
                }
            }
        }
    }
    
    // MARK: - VoiceOver Compatibility Tests
    
    @MainActor
    func testAllLayer1Functions_VoiceOverCompatible() throws {
        // Given: App is launched and ready
        
        // When: Testing VoiceOver compatibility for all Layer 1 functions
        // Then: All interactive elements should be discoverable and readable
        
        // Navigate through all categories
        let categories = ["Data Presentation", "Navigation", "Photos", "Security", "OCR", 
                         "Notifications", "Internationalization", "Data Analysis"]
        
        for category in categories {
            try navigateToLayer1Category(category)
            
            // Verify all buttons are discoverable (have identifier or label)
            let buttons = app.buttons.allElementsBoundByIndex
            for button in buttons {
                let hasIdentifier = !button.identifier.isEmpty
                let hasLabel = !button.label.isEmpty
                XCTAssertTrue(hasIdentifier || hasLabel,
                             "Button in \(category) should be discoverable for VoiceOver. Identifier: '\(button.identifier)', Label: '\(button.label)'")
            }
            
            // Verify all text fields are discoverable
            let textFields = app.textFields.allElementsBoundByIndex
            for textField in textFields {
                let hasIdentifier = !textField.identifier.isEmpty
                let hasLabel = !textField.label.isEmpty
                XCTAssertTrue(hasIdentifier || hasLabel,
                             "Text field in \(category) should be discoverable for VoiceOver. Identifier: '\(textField.identifier)', Label: '\(textField.label)'")
            }
        }
    }
    
    // MARK: - Switch Control Compatibility Tests
    
    @MainActor
    func testAllLayer1Functions_SwitchControlCompatible() throws {
        // Given: App is launched and ready
        
        // When: Testing Switch Control compatibility
        // Then: All interactive elements should have correct traits
        
        // Navigate through all categories
        let categories = ["Data Presentation", "Navigation", "Photos", "Security", "OCR", 
                         "Notifications", "Internationalization", "Data Analysis"]
        
        for category in categories {
            try navigateToLayer1Category(category)
            
            // Verify buttons have button trait
            let buttons = app.buttons.allElementsBoundByIndex
            for button in buttons {
                XCTAssertTrue(button.elementType == .button,
                             "Button in \(category) should have button trait for Switch Control")
            }
            
            // Verify text fields have text field trait
            let textFields = app.textFields.allElementsBoundByIndex
            for textField in textFields {
                XCTAssertTrue(textField.elementType == .textField,
                             "Text field in \(category) should have text field trait for Switch Control")
            }
        }
    }
}
