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

    /// Expected identifier suffix (sanitized label + type) when enableUITestIntegration is true: SixLayer.main.ui.<suffix>.
    private static func l4ContractIdentifier(sanitizedName: String, elementType: String) -> String {
        "SixLayer.main.ui.\(sanitizedName).\(elementType)"
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
        // platformPicker uses automaticCompliance(named: pickerName ?? "Picker"), so identifier suffix is "picker.View".
        let identifier = Self.l4ContractIdentifier(sanitizedName: "picker", elementType: "View")
        let el = app.findElement(byIdentifier: identifier, primaryType: .other, secondaryTypes: [.button, .picker, .segmentedControl, .any], timeout: 5.0)
        XCTAssertNotNil(el, "platformPicker: picker with identifier '\(identifier)' should exist")
        if let el = el {
            XCTAssertFalse(el.identifier.isEmpty, "platformPicker must apply a11y. Found: '\(el.identifier)'")
        }
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
}
