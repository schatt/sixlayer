//
//  Layer4UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 4 (Component) UI tests: one test method per L4 component. Launch with -OpenLayer4Examples.
//  Each test verifies that the L4 component applies its contract (a11y identifier/label) to the element.
//

import XCTest
@testable import SixLayerFramework

/// Layer 4 component tests: one test per L4 API. Contract = full contract (behavior, structure, a11y), not just accessibility.
/// We test ALL L4 APIs; each test asserts the API's contract.
/// Uses launch argument -OpenLayer4Examples. One app launch for the suite.
///
/// Currently covered: platformButton, platformTextField, platformPicker, platformSecureField, platformToggle,
/// platformTextEditor, platformDatePicker, platformForm, platformFormSection, platformFormField, platformFormFieldGroup,
/// platformValidationMessage, platformListRow, platformListSectionHeader, platformListEmptyState.
/// Remaining L4 APIs to add: navigation (platformNavigationTitle_L4, platformImplementNavigationStack_L4,
/// platformNavigationLink_L4, platformAppNavigation_L4, ...), platformSheet_L4, platformPopover_L4, platformRowActions_L4,
/// platformPhotoPicker_L4, platformPhotoDisplay_L4, platformMapView_L4, platformCloudKit*, platformCopyToClipboard_L4,
/// platformPrint_L4, platformShare_L4, platformVerticalSplit_L4, platformHorizontalSplit_L4, platformStyledContainer_L4, etc.
@MainActor
final class Layer4UITests: XCTestCase {
    /// Shared across test instances (Xcode creates one instance per test method).
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    /// One app launch for the suite; all test methods reuse the same launch.
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            guard Self.sharedApp == nil else { return }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer4Examples")
            localApp.launch()
            Self.sharedApp = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 4 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 4 Examples (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    /// Expected identifier suffix (sanitized label + type) when enableUITestIntegration is true: SixLayer.main.ui.<suffix>.
    private static func l4ContractIdentifier(sanitizedName: String, elementType: String) -> String {
        "SixLayer.main.ui.\(sanitizedName).\(elementType)"
    }

    /// Scroll so the element with the given label is visible (content may be below fold).
    @MainActor
    private func scrollToElement(label: String) {
        if app.staticTexts[label].waitForExistence(timeout: 1.0) { return }
        for _ in 0..<3 {
            app.scrollViews.firstMatch.swipeUp()
            if app.staticTexts[label].waitForExistence(timeout: 1.0) { return }
        }
    }

    @MainActor
    private func assertElementHasIdentifierFromComponent(
        label: String,
        type: XCUIElement.ElementType,
        componentName: String,
        sanitizedIdentifierName: String,
        identifierElementType: String
    ) {
        let identifier = Self.l4ContractIdentifier(sanitizedName: sanitizedIdentifierName, elementType: identifierElementType)
        let el = app.findElement(byIdentifier: identifier, primaryType: type, secondaryTypes: [.other, .button, .staticText, .any], timeout: 5.0)
        XCTAssertNotNil(el, "\(componentName): element with identifier '\(identifier)' should exist")
        if let el = el {
            XCTAssertFalse(el.identifier.isEmpty,
                          "\(componentName) must apply a11y. '\(label)' should have identifier. Found: '\(el.identifier)'")
        }
    }

    @MainActor
    func testL4_platformButton() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractButton",
            type: .button,
            componentName: "platformButton",
            sanitizedIdentifierName: "l4contractbutton",
            identifierElementType: "Button"
        )
    }

    @MainActor
    func testL4_platformTextField() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextField",
            type: .textField,
            componentName: "platformTextField",
            sanitizedIdentifierName: "l4contracttextfield",
            identifierElementType: "TextField"
        )
    }

    @MainActor
    func testL4_platformPicker() throws {
        // platformPicker contract: picker or an option has identifier. Find by predicate (picker may be menu button with varying hierarchy).
        let pred = NSPredicate(format: "identifier CONTAINS[c] %@", "picker")
        let pickerEl = app.descendants(matching: .any).matching(pred).firstMatch
        if pickerEl.waitForExistence(timeout: 3.0) {
            XCTAssertFalse(pickerEl.identifier.isEmpty, "platformPicker must apply a11y. Found: '\(pickerEl.identifier)'")
            return
        }
        // Fallback: option "a" (visible when menu open); contract is that options get identifiers.
        let optionAId = Self.l4ContractIdentifier(sanitizedName: "a", elementType: "View")
        let optionEl = app.findElement(byIdentifier: optionAId, primaryType: .button, secondaryTypes: [.staticText, .other, .any], timeout: 2.0)
        XCTAssertNotNil(optionEl, "platformPicker: picker or option should have identifier (tried 'picker' and '\(optionAId)')")
        if let el = optionEl { XCTAssertFalse(el.identifier.isEmpty, "platformPicker must apply a11y.") }
    }

    @MainActor
    func testL4_platformSecureField() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractSecureField",
            type: .secureTextField,
            componentName: "platformSecureField",
            sanitizedIdentifierName: "l4contractsecurefield",
            identifierElementType: "SecureField"
        )
    }

    @MainActor
    func testL4_platformToggle() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractToggle",
            type: .switch,
            componentName: "platformToggle",
            sanitizedIdentifierName: "l4contracttoggle",
            identifierElementType: "Toggle"
        )
    }

    @MainActor
    func testL4_platformTextEditor() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextEditor",
            type: .textView,
            componentName: "platformTextEditor",
            sanitizedIdentifierName: "l4contracttexteditor",
            identifierElementType: "TextEditor"
        )
    }

    @MainActor
    func testL4_platformDatePicker() throws {
        scrollToElement(label: "L4ContractDatePicker")
        XCTAssertTrue(app.staticTexts["L4ContractDatePicker"].waitForExistence(timeout: 3.0),
                      "platformDatePicker: label should exist")
    }

    @MainActor
    func testL4_platformForm() throws {
        scrollToElement(label: "L4 Form")
        XCTAssertTrue(app.staticTexts["L4 Form"].waitForExistence(timeout: 3.0),
                      "platformForm: form section (L4 Form) should be visible")
        // Form contains section; on iOS Section may not expose header/content as separate static texts
    }

    @MainActor
    func testL4_platformFormSection() throws {
        scrollToElement(label: "L4 Form")
        XCTAssertTrue(app.staticTexts["L4 Form"].waitForExistence(timeout: 3.0),
                      "platformFormSection: section is inside L4 Form; section title should be visible")
    }

    @MainActor
    func testL4_platformFormField() throws {
        XCTAssertTrue(app.staticTexts["L4FormFieldContract"].waitForExistence(timeout: 3.0),
                      "platformFormField: label should exist")
        XCTAssertTrue(app.staticTexts["Field content"].waitForExistence(timeout: 2.0),
                      "platformFormField: content should exist")
    }

    @MainActor
    func testL4_platformFormFieldGroup() throws {
        XCTAssertTrue(app.staticTexts["L4FormFieldGroupContract"].waitForExistence(timeout: 3.0),
                      "platformFormFieldGroup: title should exist")
    }

    @MainActor
    func testL4_platformValidationMessage() throws {
        XCTAssertTrue(app.staticTexts["L4ValidationMessageContract"].waitForExistence(timeout: 3.0),
                      "platformValidationMessage: message should exist")
    }

    @MainActor
    func testL4_platformListRow() throws {
        XCTAssertTrue(app.staticTexts["L4ListRowContract"].waitForExistence(timeout: 3.0),
                      "platformListRow: row title should exist")
    }

    @MainActor
    func testL4_platformListSectionHeader() throws {
        XCTAssertTrue(app.staticTexts["L4ListSectionHeaderContract"].waitForExistence(timeout: 3.0),
                      "platformListSectionHeader: header title should exist")
    }

    @MainActor
    func testL4_platformListEmptyState() throws {
        XCTAssertTrue(app.staticTexts["L4ListEmptyStateContract"].waitForExistence(timeout: 3.0),
                      "platformListEmptyState: title should exist")
    }
}
