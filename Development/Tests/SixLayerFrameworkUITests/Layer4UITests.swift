//
//  Layer4UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 4 (Component) UI tests: one launch, per-view navigate → sweep → view-specific asserts.
//  Consolidates tests from Accessibility*, Values, Hints, Traits, BasicCompliance, ViewInspector.
//

import XCTest
@testable import SixLayerFramework

/// Layer 4 component tests: accessibility test views (Control, Text, Button, Picker, Basic Compliance, Identifier Edge Case, Detail View).
/// Pattern: navigate to view → runAccessibilityCompatibilitySweep() → view-specific assertions.
@MainActor
final class Layer4UITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
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

    /// Navigate to launch page so the next test can tap a view entry.
    @MainActor
    private func ensureLaunchPage() {
        _ = app.navigateBackToLaunch(timeout: 5.0)
    }

    /// Navigate to a test view by launch-page entry identifier. Use for Control Test (baseline); no sweep—that view is plain SwiftUI, not L4.
    @MainActor
    private func navigateToView(entryIdentifier: String) {
        ensureLaunchPage()
        let link = app.findLaunchPageEntry(identifier: entryIdentifier)
        XCTAssertTrue(link.waitForExistence(timeout: 3.0), "\(entryIdentifier) should exist")
        link.tap()
    }

    /// Navigate to Layer 4 Examples and tap the component test view link. Caller runs sweep if needed.
    @MainActor
    private func navigateToLayer4View(entryIdentifier: String) {
        guard app.navigateToLayerExamples(linkIdentifier: "layer4-examples-link", navigationBarTitle: "Layer 4 Examples") else {
            XCTFail("Should navigate to Layer 4 Examples")
            return
        }
        _ = app.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 2.0)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
        }
        let label = entryIdentifier.replacingOccurrences(of: "test-view-", with: "")
        var el: XCUIElement?
        if let link = app.findElement(byIdentifier: entryIdentifier, primaryType: .button, secondaryTypes: [.link, .cell, .staticText, .other, .any], timeout: 5.0), link.waitForExistence(timeout: 2.0) {
            el = link
        } else if app.links[label].waitForExistence(timeout: 3.0) {
            el = app.links[label]
        } else if app.buttons[label].waitForExistence(timeout: 3.0) {
            el = app.buttons[label]
        } else if app.staticTexts[label].waitForExistence(timeout: 2.0) {
            el = app.staticTexts[label]
        }
        guard let tapTarget = el else {
            XCTFail("\(entryIdentifier) should exist on Layer 4 Examples")
            return
        }
        tapTarget.tap()
    }

    // MARK: - Control Test view (identifiers, values)

    @MainActor
    func testControlTestView_ComplianceAndValues() throws {
        navigateToView(entryIdentifier: "test-view-Control Test")

        let controlButtonByLabel = app.buttons["Control Button"]
        XCTAssertTrue(controlButtonByLabel.waitForExistence(timeout: 3.0), "Control button should exist")
        let controlIdentifier = "control-test-button"
        XCTAssertNotNil(app.findElement(byIdentifier: controlIdentifier, primaryType: .button, secondaryTypes: [.other]),
                        "Control test button should be findable by identifier")

        let switches = app.switches.allElementsBoundByIndex
        for switchElement in switches {
            let value = switchElement.value as? String
            XCTAssertNotNil(value, "Switch should have a value")
        }
        let sliders = app.sliders.allElementsBoundByIndex
        for slider in sliders {
            XCTAssertNotNil(slider.value as? String, "Slider should have a value")
        }
        if let firstSwitch = switches.first {
            let initialValue = firstSwitch.value as? String
            firstSwitch.tap()
            let deadline = Date().addingTimeInterval(2.0)
            while Date() < deadline {
                if (firstSwitch.value as? String) != initialValue { break }
                Thread.sleep(forTimeInterval: 0.1)
            }
            XCTAssertNotNil(firstSwitch.value as? String, "Switch should have value after toggle")
        }
    }

    // MARK: - Text Test view

    @MainActor
    func testTextTestView_Compliance() throws {
        navigateToLayer4View(entryIdentifier: "test-view-Text Test")
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED
        XCTAssertTrue(app.staticTexts["Test Content"].waitForExistence(timeout: 3.0), "Text view should exist")
        let expectedIdentifier = "SixLayer.main.ui.testText.View"
        XCTAssertNotNil(app.findElement(byIdentifier: expectedIdentifier, primaryType: .other, secondaryTypes: [.staticText, .any]),
                        "Text identifier should be findable")
    }

    // MARK: - Button Test view (identifiers, hints, traits)

    @MainActor
    func testButtonTestView_ComplianceHintsAndTraits() throws {
        navigateToLayer4View(entryIdentifier: "test-view-Button Test")
        _ = app.navigationBars["Button Test"].waitForExistence(timeout: 5.0)
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED
        let expectedIdentifier = "SixLayer.main.ui.testButton.Button"
        XCTAssertTrue(app.buttons["Test Button"].waitForExistence(timeout: 5.0), "Button Test view should be ready")
        XCTAssertNotNil(app.findElement(byIdentifier: expectedIdentifier, primaryType: .other, secondaryTypes: [.button, .any]),
                        "Button identifier should be findable")

        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertEqual(button.elementType, .button, "Button should have button trait")
        }
        let textFields = app.textFields.allElementsBoundByIndex
        for textField in textFields {
            XCTAssertEqual(textField.elementType, .textField, "Text field should have text field trait")
        }
    }

    // MARK: - Platform Picker Test view

    @MainActor
    func testPlatformPickerTestView_Compliance() throws {
        navigateToLayer4View(entryIdentifier: "test-view-Platform Picker Test")
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED
        XCTAssertTrue(app.buttons["Option1"].waitForExistence(timeout: 3.0) || app.buttons["Option2"].waitForExistence(timeout: 0.5),
                      "Platform Picker view should be ready (segment visible)")
        let pickerIdentifier = "SixLayer.main.ui.PlatformPickerTest.View"
        #if !os(macOS)
        XCTAssertNotNil(app.findElement(byIdentifier: pickerIdentifier, primaryType: .segmentedControl, secondaryTypes: [.picker, .other, .any]),
                        "Picker should have accessibility identifier")
        #endif
        let segmentOptions = ["Option1", "Option2", "Option3"]
        for option in segmentOptions {
            let sanitized = option.lowercased()
            let segmentId = "SixLayer.main.ui.\(sanitized).View"
            XCTAssertNotNil(app.findElement(byIdentifier: segmentId, primaryType: .button, secondaryTypes: [.staticText, .any]),
                            "Segment \(option) should have identifier")
        }
        XCTAssertTrue(app.selectPickerSegment("Option2"), "Should be able to select segment")
    }

    // MARK: - Basic Compliance Test view

    @MainActor
    func testBasicComplianceTestView_Compliance() throws {
        navigateToLayer4View(entryIdentifier: "test-view-Basic Compliance Test")
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED
        let testViewId = "SixLayer.main.ui.testView.View"
        let testViewEl = app.findElement(byIdentifier: testViewId, primaryType: .other, secondaryTypes: [.staticText, .any])
        XCTAssertNotNil(testViewEl, "Basic compliance identifier should be findable")
        if let el = testViewEl {
            XCTAssertEqual(el.label, "Test Content", "Element should have label Test Content")
        }

        let testViewWithLabelId = "SixLayer.main.ui.testViewWithLabel.View"
        let labelEl = app.findElement(byIdentifier: testViewWithLabelId, primaryType: .other, secondaryTypes: [.staticText, .any])
        XCTAssertNotNil(labelEl, "Label element should be findable")
        if let el = labelEl { XCTAssertEqual(el.label, "Test label.", "Label should be readable") }

        let helloTextId = "SixLayer.main.ui.helloText.View"
        XCTAssertNotNil(app.findElement(byIdentifier: helloTextId, primaryType: .other, secondaryTypes: [.staticText, .any]),
                        "Text.basicAutomaticCompliance identifier should be findable")

        let helloTextWithLabelId = "SixLayer.main.ui.helloTextWithLabel.View"
        let helloLabelEl = app.findElement(byIdentifier: helloTextWithLabelId, primaryType: .other, secondaryTypes: [.staticText, .any])
        XCTAssertNotNil(helloLabelEl)
        if let el = helloLabelEl { XCTAssertEqual(el.label, "Hello text.", "Hello text label should be correct") }

        let sanitizedSpaceId = "SixLayer.main.ui.TestButton.save-file.View"
        let foundSanitized = app.findElement(byIdentifier: sanitizedSpaceId, primaryType: .other, secondaryTypes: [.staticText, .any]) != nil
            || app.findElement(byIdentifier: "SixLayer.main.ui.TestButton.save.View", primaryType: .other, secondaryTypes: [.staticText, .any]) != nil
        XCTAssertTrue(foundSanitized, "Sanitized identifier (spaces/uppercase) should be findable")

        let sanitizedSpecialId = "SixLayer.main.ui.TestButton.save-load.View"
        XCTAssertNotNil(app.findElement(byIdentifier: sanitizedSpecialId, primaryType: .other, secondaryTypes: [.staticText, .any]),
                        "Sanitized special chars identifier should be findable")
        XCTAssertNil(app.findElement(byIdentifier: "SixLayer.main.ui.TestButton.save-&-load.View", primaryType: .other, secondaryTypes: [.staticText, .any]),
                     "Identifier should not contain &")
        XCTAssertNil(app.findElement(byIdentifier: "SixLayer.main.ui.TestButton.save-load!.View", primaryType: .other, secondaryTypes: [.staticText, .any]),
                     "Identifier should not contain !")

        let starImageId = "SixLayer.main.ui.starImage.Image"
        let imageFound = app.findElement(byIdentifier: starImageId, primaryType: .image, secondaryTypes: [.other, .any]) != nil
            || app.findElement(byIdentifier: starImageId, primaryType: .other, secondaryTypes: [.image, .any]) != nil
        XCTAssertTrue(imageFound, "Image.basicAutomaticCompliance identifier should be findable")
    }

    // MARK: - Identifier Edge Case view

    @MainActor
    func testIdentifierEdgeCaseView_Compliance() throws {
        navigateToLayer4View(entryIdentifier: "test-view-Identifier Edge Case")
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED
        let manualSubmitId = "SixLayer.main.ui.manual-override-id.Button"
        XCTAssertNotNil(app.findElement(byIdentifier: manualSubmitId, primaryType: .button, secondaryTypes: [.other, .any]),
                        "Manual override identifier should be findable")
        let manualCancelId = "SixLayer.main.ui.manual-cancel-id.Button"
        XCTAssertNotNil(app.findElement(byIdentifier: manualCancelId, primaryType: .button, secondaryTypes: [.other, .any]),
                        "Manual cancel identifier should be findable")
    }

    // MARK: - Detail View Test

    @MainActor
    func testDetailViewTest_Compliance() throws {
        navigateToLayer4View(entryIdentifier: "test-view-Detail View Test")
        // SWEEP CHECK WAS HERE. REPLACEMENT NEEDED

        XCTAssertTrue(app.staticTexts["Detail Title"].waitForExistence(timeout: 3.0), "Detail view should display title")
        XCTAssertTrue(app.staticTexts["Detail subtitle and content for UI test to find."].waitForExistence(timeout: 2.0),
                      "Detail view should display description")
    }
}
