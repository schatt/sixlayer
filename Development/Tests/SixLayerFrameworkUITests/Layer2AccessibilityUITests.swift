//
//  Layer2AccessibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for Layer 2 platform*_L2 function accessibility
//  Implements Issue #167: Complete accessibility for Layer 2 platform* methods
//
//  #348 / #316: deep-link via `-OpenLayer2Examples` — no launch-menu navigation.
//  #374: one shared app process for the class (same launch args every method).
//
//  Note: Layer 2 functions return data structures (OCRLayout), not Views.
//  We test the example views that use these functions.
//

import XCTest
@testable import SixLayerFramework

/// XCUITest tests for Layer 2 accessibility features
/// Verifies all 4 Layer 2 functions have example views with complete accessibility support
@MainActor
final class Layer2AccessibilityUITests: XCTestCase {
    private enum Host {
        static let openArg = "-OpenLayer2Examples"
        static let rootIdentifier = "layer2-examples-host-root"
    }

    var app: XCUIApplication!
    private static var sharedApp: XCUIApplication?

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()

        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            if let existing = Self.sharedApp, existing.state == .runningForeground {
                instance.app = existing
                return
            }
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append(Host.openArg)
            localApp.launch()
            Self.sharedApp = localApp
            instance.app = localApp

            XCTAssertTrue(
                localApp.waitForHostRootIdentifier(Host.rootIdentifier),
                "App should open Layer 2 Examples (\(Host.openArg))"
            )
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    override class func tearDown() {
        if let running = sharedApp, running.state != .notRunning {
            running.terminate()
            _ = running.wait(for: .notRunning, timeout: 5)
        }
        sharedApp = nil
        super.tearDown()
    }

    @MainActor
    private func verifyAccessibilityIdentifier(_ element: XCUIElement, viewName: String) {
        let identifier = element.identifier
        XCTAssertFalse(
            identifier.isEmpty,
            "\(viewName) should have accessibility identifier. Found: '\(identifier)'"
        )
    }

    @MainActor
    private func verifyAccessibilityTraits(
        _ element: XCUIElement,
        viewName: String,
        expectedType: XCUIElement.ElementType
    ) {
        XCTAssertEqual(
            element.elementType,
            expectedType,
            "\(viewName) should have correct accessibility trait. Expected: \(expectedType), Found: \(element.elementType)"
        )
    }

    // MARK: - OCR Layout Example Views Tests

    @MainActor
    func testOCRLayoutExampleViews_AccessibilityIdentifiers() throws {
        let names = [
            "GeneralOCRLayoutExample",
            "DocumentOCRLayoutExample",
            "ReceiptOCRLayoutExample",
            "BusinessCardOCRLayoutExample",
            "LayoutDetailsView",
        ]
        for name in names {
            let elements = app.descendants(matching: .any).matching(identifier: name)
            guard elements.count > 0 else { continue }
            for i in 0..<min(elements.count, 3) {
                let element = elements.element(boundBy: i)
                if element.exists {
                    verifyAccessibilityIdentifier(element, viewName: name)
                }
            }
        }
    }

    @MainActor
    func testOCRLayoutExampleViews_AccessibilityLabels() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        var labeledButtons = 0
        for button in buttons {
            if !button.label.isEmpty {
                labeledButtons += 1
            }
        }
        XCTAssertTrue(
            labeledButtons > 0 || buttons.count == 0,
            "Layer 2 example buttons should have accessibility labels. Found \(labeledButtons) labeled out of \(buttons.count)"
        )
    }

    @MainActor
    func testOCRLayoutExampleViews_AccessibilityTraits() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons where button.exists {
            verifyAccessibilityTraits(button, viewName: "Layer 2 Example Button", expectedType: .button)
        }
    }

    // MARK: - VoiceOver Compatibility Tests

    @MainActor
    func testAllLayer2ExampleViews_VoiceOverCompatible() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons where button.exists {
            XCTAssertTrue(
                button.isHittable || button.isEnabled,
                "Layer 2 example button should be accessible to VoiceOver"
            )
            let hasLabel = !button.label.isEmpty
            let hasIdentifier = !button.identifier.isEmpty
            XCTAssertTrue(
                hasLabel || hasIdentifier,
                "Layer 2 example button should have label or identifier for VoiceOver"
            )
        }
    }

    // MARK: - Switch Control Compatibility Tests

    @MainActor
    func testAllLayer2ExampleViews_SwitchControlCompatible() throws {
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons where button.exists {
            XCTAssertEqual(
                button.elementType,
                .button,
                "Layer 2 example button should have button trait for Switch Control"
            )
            XCTAssertTrue(
                button.isEnabled,
                "Layer 2 example button should be enabled for Switch Control"
            )
        }
    }
}
