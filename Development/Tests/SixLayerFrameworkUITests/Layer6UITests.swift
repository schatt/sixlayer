//
//  Layer6UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 6 UI tests: one test method per L6 function. Launch with -OpenLayer6Examples.
//  Each test verifies that the modifier applies a11y (automaticCompliance) to the element it wraps.
//

import XCTest
@testable import SixLayerFramework

/// Layer 6 UI tests: one test per L6 function so the run shows a clear pass count per function.
/// Uses launch argument -OpenLayer6Examples. Compile-time conditionals for platform-specific behavior.
@MainActor
final class Layer6UITests: XCTestCase {
    /// Shared across test instances (Xcode creates one instance per test method).
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication! { Self.sharedApp! }

    /// One app launch for the suite; all 4 test methods reuse the same launch.
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        MainActor.assumeIsolated {
            guard Self.sharedApp == nil else { return }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer6Examples")
            localApp.launch()
            Self.sharedApp = localApp
            XCTAssertTrue(localApp.navigationBars["Layer 6 Examples"].waitForExistence(timeout: 5.0),
                          "App should open on Layer 6 Examples (launch arg)")
        }
    }

    nonisolated override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    private static let expectedSectionTitle = "Cross-Platform Optimizations"

    @MainActor
    private func assertElementHasIdentifierFromModifier(label: String, type: XCUIElement.ElementType, modifierName: String) {
        let el: XCUIElement
        if type == .button {
            el = app.buttons[label].firstMatch
        } else {
            el = app.staticTexts[label].firstMatch
        }
        XCTAssertTrue(el.waitForExistence(timeout: 2.0), "\(modifierName): element '\(label)' should exist")
        XCTAssertFalse(el.identifier.isEmpty,
                       "\(modifierName) must apply a11y to the element it wraps. '\(label)' should have identifier. Found: '\(el.identifier)'")
    }

    @MainActor
    func testL6_platformSpecificOptimizations() throws {
        assertElementHasIdentifierFromModifier(label: "L6ContractText", type: .staticText, modifierName: "platformSpecificOptimizations(for:)")
        assertElementHasIdentifierFromModifier(label: "L6ContractButton", type: .button, modifierName: "platformSpecificOptimizations(for:)")
    }

    @MainActor
    func testL6_performanceOptimizations() throws {
        assertElementHasIdentifierFromModifier(label: "L6PerformanceContractText", type: .staticText, modifierName: "performanceOptimizations(using:)")
    }

    @MainActor
    func testL6_uiPatternOptimizations() throws {
        assertElementHasIdentifierFromModifier(label: "L6UIPatternContractText", type: .staticText, modifierName: "uiPatternOptimizations(using:)")
    }

    @MainActor
    func testL6_platformNavigationStackEnhancements() throws {
        #if os(iOS)
        let navStackSection = app.staticTexts["Navigation Stack Enhancements"].firstMatch
        XCTAssertTrue(navStackSection.waitForExistence(timeout: 2.0),
                      "platformNavigationStackEnhancements_L6 (iOS): section should be visible")
        #elseif os(macOS)
        let navStackSection = app.staticTexts["Navigation Stack Enhancements"].firstMatch
        XCTAssertTrue(navStackSection.waitForExistence(timeout: 2.0),
                      "platformNavigationStackEnhancements_L6 (macOS): section should be visible")
        #elseif os(tvOS) || os(watchOS) || os(visionOS)
        XCTAssertTrue(app.staticTexts[Self.expectedSectionTitle].waitForExistence(timeout: 2.0),
                      "platformNavigationStackEnhancements_L6 (other): Cross-Platform Optimizations section visible")
        #endif
    }
}
