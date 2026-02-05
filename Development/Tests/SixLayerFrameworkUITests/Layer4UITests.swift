//
//  Layer4UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 4 (Component) UI tests: one test method per L4 component. Launch with -OpenLayer4Examples.
//  Each test verifies that the L4 component applies its contract (a11y identifier/label) to the element.
//

import XCTest
@testable import SixLayerFramework

/// Layer 4 component tests: one test per L4 component (platformButton, platformTextField, platformPicker, platformSecureField).
/// Uses launch argument -OpenLayer4Examples. One app launch for the suite.
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

    @MainActor
    private func assertElementHasIdentifierFromComponent(
        label: String,
        type: XCUIElement.ElementType,
        componentName: String
    ) {
        let el: XCUIElement
        switch type {
        case .button:
            el = app.buttons[label].firstMatch
        case .textField:
            el = app.textFields[label].firstMatch
        case .secureTextField:
            el = app.secureTextFields[label].firstMatch
        default:
            el = app.staticTexts[label].firstMatch
        }
        XCTAssertTrue(el.waitForExistence(timeout: 2.0),
                       "\(componentName): element '\(label)' should exist")
        XCTAssertFalse(el.identifier.isEmpty,
                       "\(componentName) must apply a11y to the element. '\(label)' should have identifier. Found: '\(el.identifier)'")
    }

    @MainActor
    func testL4_platformButton() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractButton",
            type: .button,
            componentName: "platformButton"
        )
    }

    @MainActor
    func testL4_platformTextField() throws {
        // TextField may be found by placeholder/label; framework uses title as label.
        assertElementHasIdentifierFromComponent(
            label: "L4ContractTextField",
            type: .textField,
            componentName: "platformTextField"
        )
    }

    @MainActor
    func testL4_platformPicker() throws {
        // Picker contract: picker and options get identifiers. Assert picker has identifier (by label).
        let pickerLabel = "L4ContractPicker"
        let pickerEl = app.otherElements[pickerLabel].firstMatch
        if !pickerEl.waitForExistence(timeout: 2.0) {
            // On some platforms picker may appear as button or different type
            let alt = app.buttons[pickerLabel].firstMatch
            XCTAssertTrue(alt.waitForExistence(timeout: 2.0), "platformPicker: '\(pickerLabel)' should exist")
            XCTAssertFalse(alt.identifier.isEmpty, "platformPicker must apply a11y. Found: '\(alt.identifier)'")
            return
        }
        XCTAssertFalse(pickerEl.identifier.isEmpty,
                       "platformPicker must apply a11y to the picker. Found: '\(pickerEl.identifier)'")
    }

    @MainActor
    func testL4_platformSecureField() throws {
        assertElementHasIdentifierFromComponent(
            label: "L4ContractSecureField",
            type: .secureTextField,
            componentName: "platformSecureField"
        )
    }
}
