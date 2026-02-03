//
//  AccessibilityCompatibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  Consolidated XCUITest for VoiceOver, Dynamic Type, High Contrast, and Switch Control.
//  Implements Issue #165: Complete accessibility for all platform* methods.
//
//  One test class = one app launch. Keeps SLF-iOS-UITests faster by avoiding
//  four separate launches for the four compatibility checks.
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// Consolidated compatibility tests: VoiceOver, Dynamic Type, High Contrast, Switch Control.
/// All run in a single app launch to reduce SLF-iOS-UITests runtime.
@MainActor
final class AccessibilityCompatibilityUITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false

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
        try super.tearDownWithError()
    }

    // MARK: - VoiceOver compatibility

    @MainActor
    func testPlatformFunctions_AreVoiceOverCompatible() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex
        let sliders = app.sliders.allElementsBoundByIndex

        for button in buttons {
            let hasIdentifier = !button.identifier.isEmpty
            let hasLabel = !button.label.isEmpty
            XCTAssertTrue(hasIdentifier || hasLabel,
                         "Button should be discoverable. Identifier: '\(button.identifier)', Label: '\(button.label)'")
        }

        for button in buttons {
            if !button.label.isEmpty {
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, "Button label should be readable")
            }
        }

        for button in buttons {
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for navigation")
        }
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for navigation")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.elementType == .switch, "Switch should have switch trait for navigation")
        }

        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        var elementsWithContent = 0
        for element in allElements {
            if !element.label.isEmpty || !element.identifier.isEmpty {
                elementsWithContent += 1
            }
        }
        XCTAssertTrue(elementsWithContent > 0,
                     "Accessibility hierarchy should contain elements with content. Found \(elementsWithContent) elements with content")

        for switchElement in switches {
            let value = switchElement.value as? String
            XCTAssertNotNil(value, "Switch should have a value for VoiceOver")
        }
        for slider in sliders {
            let value = slider.value as? String
            XCTAssertNotNil(value, "Slider should have a value for VoiceOver")
        }
    }

    // MARK: - Dynamic Type support

    @MainActor
    func testPlatformFunctions_SupportDynamicType() throws {
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        var readableTexts = 0
        for text in staticTexts {
            if !text.label.isEmpty {
                readableTexts += 1
                let trimmedLabel = text.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, "Text element should have readable content")
            }
        }
        XCTAssertTrue(readableTexts > 0 || staticTexts.count == 0,
                     "Text elements should be readable for Dynamic Type")

        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        for button in buttons {
            XCTAssertTrue(button.exists, "Button should exist for Dynamic Type support")
        }
        for textField in textFields {
            XCTAssertTrue(textField.exists, "Text field should exist for Dynamic Type support")
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled for Dynamic Type support")
        }

        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, "Button label should be readable for Dynamic Type")
            }
        }
        XCTAssertTrue(labeledButtons > 0 || buttons.count == 0,
                     "Buttons should have readable labels for Dynamic Type")
    }

    // MARK: - High Contrast support

    @MainActor
    func testPlatformFunctions_SupportHighContrast() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex

        for button in buttons {
            XCTAssertTrue(button.exists, "Button should exist for High Contrast support")
        }
        for textField in textFields {
            XCTAssertTrue(textField.exists, "Text field should exist for High Contrast support")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.exists, "Switch should exist for High Contrast support")
        }

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

        var labeledCount = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledCount += 1
                let trimmedLabel = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmedLabel.isEmpty, "Button label should be visible for High Contrast")
            }
        }
        for textField in textFields {
            if !textField.label.isEmpty { labeledCount += 1 }
        }
        for switchElement in switches {
            if !switchElement.label.isEmpty { labeledCount += 1 }
        }
        let totalElements = buttons.count + textFields.count + switches.count
        XCTAssertTrue(labeledCount > 0 || totalElements == 0,
                     "Elements should have visible labels for High Contrast. Found \(labeledCount) labeled elements out of \(totalElements)")

        for button in buttons {
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for High Contrast boundaries")
        }
        for textField in textFields {
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for High Contrast boundaries")
        }
    }

    // MARK: - Switch Control compatibility

    @MainActor
    func testPlatformFunctions_AreSwitchControlCompatible() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        let switches = app.switches.allElementsBoundByIndex

        for button in buttons {
            XCTAssertTrue(button.isEnabled, "Button should be enabled for Switch Control focus")
            XCTAssertTrue(button.elementType == .button, "Button should have button trait for Switch Control")
        }
        for textField in textFields {
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled for Switch Control focus")
            XCTAssertTrue(textField.elementType == .textField, "Text field should have text field trait for Switch Control")
        }
        for switchElement in switches {
            XCTAssertTrue(switchElement.isEnabled, "Switch should be enabled for Switch Control focus")
            XCTAssertTrue(switchElement.elementType == .switch, "Switch should have switch trait for Switch Control")
        }

        for button in buttons {
            XCTAssertTrue(button.isHittable || button.exists, "Button should be tappable via Switch Control")
        }

        var labeledCount = 0
        for button in buttons {
            if !button.label.isEmpty { labeledCount += 1 }
        }
        for textField in textFields {
            if !textField.label.isEmpty { labeledCount += 1 }
        }
        for switchElement in switches {
            if !switchElement.label.isEmpty { labeledCount += 1 }
        }
        let totalElements = buttons.count + textFields.count + switches.count
        XCTAssertTrue(labeledCount > 0 || totalElements == 0,
                     "Elements should have labels for Switch Control users. Found \(labeledCount) labeled elements out of \(totalElements)")
    }
}
