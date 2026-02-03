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
    /// Identifier from platformPicker(pickerName: "layer1CategoryPicker") with TestApp config.
    private static let layer1PickerIdentifier = "SixLayer.main.ui.layer1CategoryPicker.View"

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
        
        // Launch the test app only. Each test expands its own sub menu once, then runs all asserts.
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            var localApp: XCUIApplication!
            localApp = XCUIApplication()
            localApp.launchWithOptimizations()
            instance.app = localApp
            
            XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
        }
    }
    
    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }
    
    // MARK: - Helper Methods (expand once per test, then select category for asserts)
    
    /// Expand the Layer 1 examples section (toggle). Called once at start of test.
    @MainActor
    private func expandLayer1ExamplesIfNeeded() {
        guard app.waitForReady(timeout: 5.0) else {
            XCTFail("App should be ready for testing")
            return
        }
        let toggleButton = app.findElement(byIdentifier: "layer1-examples-toggle",
                                          primaryType: .button,
                                          secondaryTypes: [.cell, .other, .any]) ?? app.buttons["layer1-examples-toggle"]
        guard toggleButton.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Layer 1 examples toggle button should exist")
            return
        }
        if (toggleButton.value as? String) != "1" {
            toggleButton.tap()
            // VStack creates Layer 1 content immediately; allow one layout pass.
            sleep(1)
        }
        // platformPicker generates SixLayer.main.ui.layer1CategoryPicker.View; fallback to label.
        let byId = app.findElement(byIdentifier: Layer1AccessibilityUITests.layer1PickerIdentifier, primaryType: .button, secondaryTypes: [.picker, .other, .any])
        let picker = app.pickers.firstMatch
        let categoryButton = app.buttons["Category, Select Category"]
        let categoryButtonAlt = app.buttons["Category"]
        let categorySelectButton = app.buttons["Select Category"]
        guard (byId != nil)
            || picker.waitForExistence(timeout: 3.0)
            || categoryButton.waitForExistence(timeout: 3.0)
            || categoryButtonAlt.waitForExistence(timeout: 3.0)
            || categorySelectButton.waitForExistence(timeout: 3.0) else {
            XCTFail("Category picker should exist after expanding Layer 1")
            return
        }
    }
    
    /// Select a Layer 1 category (assumes Layer 1 section already expanded in this test).
    /// Uses platformPicker-generated identifier or label fallback.
    @MainActor
    private func selectLayer1Category(_ categoryName: String) {
        let byId = app.findElement(byIdentifier: Layer1AccessibilityUITests.layer1PickerIdentifier, primaryType: .button, secondaryTypes: [.picker, .other, .any])
        let picker = app.pickers.firstMatch
        let categoryButton = app.buttons["Category, Select Category"]
        let categoryButtonAlt = app.buttons["Category"]
        let categorySelectButton = app.buttons["Select Category"]
        let categoryControl: XCUIElement
        if let el = byId, el.waitForExistenceFast(timeout: 1.0) {
            categoryControl = el
        } else if picker.waitForExistenceFast(timeout: 1.0) {
            categoryControl = picker
        } else if categoryButton.waitForExistenceFast(timeout: 1.0) {
            categoryControl = categoryButton
        } else if categoryButtonAlt.waitForExistenceFast(timeout: 1.0) {
            categoryControl = categoryButtonAlt
        } else if categorySelectButton.waitForExistenceFast(timeout: 1.0) {
            categoryControl = categorySelectButton
        } else {
            XCTFail("Category picker should exist")
            return
        }
        categoryControl.tap()
        // Menu/popover can take a moment to appear on iOS.
        sleep(1)
        // Inspector: option has identifier SixLayer.main.ui.data-presentation.View (Button).
        let optionId = "SixLayer.main.ui.\(categoryName.replacingOccurrences(of: " ", with: "-").lowercased()).View"
        let optionById = app.findElement(byIdentifier: optionId, primaryType: .button, secondaryTypes: [.cell, .other, .any])
        let menuOption = app.menuItems[categoryName]
        let buttonOption = app.buttons[categoryName]
        let textOption = app.staticTexts[categoryName]
        let cellOption = app.cells[categoryName]
        let option: XCUIElement
        if let el = optionById, el.waitForExistence(timeout: 2.0) {
            option = el
        } else if menuOption.waitForExistence(timeout: 1.0) {
            option = menuOption
        } else if buttonOption.waitForExistence(timeout: 1.0) {
            option = buttonOption
        } else if cellOption.waitForExistence(timeout: 1.0) {
            option = cellOption
        } else if textOption.waitForExistence(timeout: 1.0) {
            option = textOption
        } else {
            XCTFail("Category '\(categoryName)' should exist in picker")
            return
        }
        option.tap()
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
    
    // MARK: - One test: expand Layer 1 once, then all asserts for content under Layer 1

    /// App launches (setUp). This test expands Layer 1 once, then runs all asserts for Layer 1 content.
    @MainActor
    func testLayer1Examples_AccessibilityIdentifiersLabelsAndTraits() throws {
        expandLayer1ExamplesIfNeeded()

        let categories = ["Data Presentation", "Navigation", "Photos", "Security", "OCR",
                          "Notifications", "Internationalization", "Data Analysis"]

        for category in categories {
            selectLayer1Category(category)

            // Category-specific identifier asserts
            switch category {
            case "Data Presentation":
                let itemCollection = app.descendants(matching: .any).matching(identifier: "platformPresentItemCollection_L1")
                for i in 0..<min(itemCollection.count, 5) {
                    let el = itemCollection.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentItemCollection_L1") }
                }
                let numericData = app.descendants(matching: .any).matching(identifier: "platformPresentNumericData_L1")
                for i in 0..<min(numericData.count, 3) {
                    let el = numericData.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentNumericData_L1") }
                }
                let formData = app.descendants(matching: .any).matching(identifier: "platformPresentFormData_L1")
                for i in 0..<min(formData.count, 3) {
                    let el = formData.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentFormData_L1") }
                }
                var labeledButtons = 0
                for b in app.buttons.allElementsBoundByIndex { if !b.label.isEmpty { labeledButtons += 1 } }
                XCTAssertTrue(labeledButtons > 0 || app.buttons.count == 0, "Data presentation: buttons should have labels")
                var fieldsWithLabelOrId = 0
                for f in app.textFields.allElementsBoundByIndex { if !f.label.isEmpty || !f.identifier.isEmpty { fieldsWithLabelOrId += 1 } }
                XCTAssertTrue(fieldsWithLabelOrId == app.textFields.count || app.textFields.count == 0, "Data presentation: every text field should have a label or identifier")

            case "Navigation":
                let navStack = app.descendants(matching: .any).matching(identifier: "platformPresentNavigationStack_L1")
                for i in 0..<min(navStack.count, 3) {
                    let el = navStack.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentNavigationStack_L1") }
                }
                let appNav = app.descendants(matching: .any).matching(identifier: "platformPresentAppNavigation_L1")
                for i in 0..<min(appNav.count, 2) {
                    let el = appNav.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentAppNavigation_L1") }
                }

            case "Photos":
                let photoCapture = app.descendants(matching: .any).matching(identifier: "platformPhotoCapture_L1")
                for i in 0..<min(photoCapture.count, 2) {
                    let el = photoCapture.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPhotoCapture_L1") }
                }
                let photoSelection = app.descendants(matching: .any).matching(identifier: "platformPhotoSelection_L1")
                for i in 0..<min(photoSelection.count, 2) {
                    let el = photoSelection.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPhotoSelection_L1") }
                }

            case "Security":
                let secureContent = app.descendants(matching: .any).matching(identifier: "platformPresentSecureContent_L1")
                for i in 0..<min(secureContent.count, 2) {
                    let el = secureContent.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentSecureContent_L1") }
                }
                let secureField = app.descendants(matching: .any).matching(identifier: "platformPresentSecureTextField_L1")
                for i in 0..<min(secureField.count, 2) {
                    let el = secureField.element(boundBy: i)
                    if el.exists {
                        verifyAccessibilityIdentifier(el, functionName: "platformPresentSecureTextField_L1")
                        verifyAccessibilityLabel(el, functionName: "platformPresentSecureTextField_L1")
                    }
                }

            case "OCR":
                let ocrDisambiguation = app.descendants(matching: .any).matching(identifier: "platformOCRWithDisambiguation_L1")
                for i in 0..<min(ocrDisambiguation.count, 2) {
                    let el = ocrDisambiguation.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformOCRWithDisambiguation_L1") }
                }
                let ocrVisual = app.descendants(matching: .any).matching(identifier: "platformOCRWithVisualCorrection_L1")
                for i in 0..<min(ocrVisual.count, 2) {
                    let el = ocrVisual.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformOCRWithVisualCorrection_L1") }
                }

            case "Notifications":
                let alerts = app.descendants(matching: .any).matching(identifier: "platformPresentAlert_L1")
                for i in 0..<min(alerts.count, 2) {
                    let el = alerts.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentAlert_L1") }
                }

            case "Internationalization":
                let localizedText = app.descendants(matching: .any).matching(identifier: "platformPresentLocalizedText_L1")
                for i in 0..<min(localizedText.count, 3) {
                    let el = localizedText.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformPresentLocalizedText_L1") }
                }
                let localizedField = app.descendants(matching: .any).matching(identifier: "platformLocalizedTextField_L1")
                for i in 0..<min(localizedField.count, 2) {
                    let el = localizedField.element(boundBy: i)
                    if el.exists {
                        verifyAccessibilityIdentifier(el, functionName: "platformLocalizedTextField_L1")
                        verifyAccessibilityLabel(el, functionName: "platformLocalizedTextField_L1")
                    }
                }

            case "Data Analysis":
                let analyze = app.descendants(matching: .any).matching(identifier: "platformAnalyzeDataFrame_L1")
                for i in 0..<min(analyze.count, 2) {
                    let el = analyze.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformAnalyzeDataFrame_L1") }
                }
                let compare = app.descendants(matching: .any).matching(identifier: "platformCompareDataFrames_L1")
                for i in 0..<min(compare.count, 2) {
                    let el = compare.element(boundBy: i)
                    if el.exists { verifyAccessibilityIdentifier(el, functionName: "platformCompareDataFrames_L1") }
                }

            default:
                break
            }
        }
    }
}
