//
//  Layer6UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 6 UI tests: one test method per L6 function. Launch with -OpenLayer6Examples.
//  Each test verifies that the modifier applies a11y (automaticCompliance) to the element it wraps.
//  #373: one shared app process for the class (same launch args every method).
//

import XCTest
@testable import SixLayerFramework

/// Layer 6 UI tests: one test per L6 function so the run shows a clear pass count per function.
/// Uses launch argument -OpenLayer6Examples. One app launch for the suite (#373).
@MainActor
final class Layer6UITests: SixLayerUITestCase {
    private nonisolated static let rootReadyTimeout: TimeInterval = 8.0
    private nonisolated static let quickWait: TimeInterval = 0.5
    nonisolated(unsafe) private var app: XCUIApplication!

    nonisolated(unsafe) private static var sharedApp: XCUIApplication?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            if let existing = Self.sharedApp, existing.state == .runningForeground {
                instance.app = existing
                return
            }

            if let running = Self.sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5.0)
            }
            Self.sharedApp = nil

            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenLayer6Examples")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(localApp.wait(for: .runningForeground, timeout: Self.rootReadyTimeout),
                          "App should reach foreground")
            XCTAssertTrue(
                localApp.waitForHostRootIdentifier("layer6-examples-host-root", timeout: Self.rootReadyTimeout),
                "App should open on Layer 6 Examples (launch arg)"
            )
            Self.sharedApp = localApp
        }
    }

    nonisolated override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    override class func tearDown() {
        MainActor.assumeIsolated {
            if let running = sharedApp, running.state != .notRunning {
                running.terminate()
                _ = running.wait(for: .notRunning, timeout: 5.0)
            }
            sharedApp = nil
        }
        super.tearDown()
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
        XCTAssertTrue(el.waitForExistence(timeout: Self.quickWait), "\(modifierName): element '\(label)' should exist")
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
        XCTAssertTrue(navStackSection.waitForExistence(timeout: Self.quickWait),
                      "platformNavigationStackEnhancements_L6 (iOS): section should be visible")
        #elseif os(macOS)
        let navStackSection = app.staticTexts["Navigation Stack Enhancements"].firstMatch
        XCTAssertTrue(navStackSection.waitForExistence(timeout: Self.quickWait),
                      "platformNavigationStackEnhancements_L6 (macOS): section should be visible")
        #elseif os(tvOS) || os(watchOS) || os(visionOS)
        XCTAssertTrue(app.staticTexts[Self.expectedSectionTitle].waitForExistence(timeout: Self.quickWait),
                      "platformNavigationStackEnhancements_L6 (other): Cross-Platform Optimizations section visible")
        #endif
    }
}
