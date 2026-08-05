//
//  Layer5UITests.swift
//  SixLayerFrameworkUITests
//
//  Layer 5 UI tests: one test method per L5 accessibility modifier. Launch with -OpenLayer5Accessibility.
//  Each test verifies that the modifier applies a11y (automaticCompliance) to the element it wraps.
//
//  #348: exact host-root + exactNamed contract ids — no label / type OR ladders.
//  #373: one shared app process for the class (same launch args every method).
//

import XCTest
@testable import SixLayerFramework

/// Layer 5 UI tests: one test per L5 accessibility modifier so the run shows a clear pass count per function.
/// Uses launch argument -OpenLayer5Accessibility. One app launch for the suite (#373).
@MainActor
final class Layer5UITests: SixLayerUITestCase {
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
            localApp.launchArguments.append("-OpenLayer5Accessibility")
            localApp.launch()
            instance.app = localApp
            XCTAssertTrue(localApp.wait(for: .runningForeground, timeout: Self.rootReadyTimeout),
                          "App should reach foreground")
            XCTAssertTrue(
                localApp.waitForHostRootIdentifier("layer5-examples-host-root", timeout: Self.rootReadyTimeout),
                "App should open on Layer 5 Examples (launch arg)"
            )
            // Assign only after host land succeeds (#370).
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

    @MainActor
    private func assertContractIdentifier(_ identifier: String, modifierName: String) {
        XCTAssertNotNil(
            app.waitForExactIdentifier(identifier, timeout: Self.quickWait),
            "\(modifierName): exactNamed '\(identifier)' should exist"
        )
        let el = app.elementMatchingExactIdentifier(identifier)
        XCTAssertFalse(
            el.identifier.isEmpty,
            "\(modifierName) must apply a11y to the element it wraps. Found: '\(el.identifier)'"
        )
    }

    @MainActor
    func testL5_accessibilityEnhanced() throws {
        assertContractIdentifier("L5AccessibilityEnhancedContract", modifierName: "accessibilityEnhanced()")
    }

    @MainActor
    func testL5_voiceOverEnabled() throws {
        assertContractIdentifier("L5VoiceOverContract", modifierName: "voiceOverEnabled()")
    }

    @MainActor
    func testL5_keyboardNavigable() throws {
        assertContractIdentifier("L5KeyboardNavigableContract", modifierName: "keyboardNavigable()")
    }

    @MainActor
    func testL5_highContrastEnabled() throws {
        assertContractIdentifier("L5HighContrastContract", modifierName: "highContrastEnabled()")
    }
}
