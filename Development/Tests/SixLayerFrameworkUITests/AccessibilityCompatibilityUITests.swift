//
//  AccessibilityCompatibilityUITests.swift
//  SixLayerFrameworkUITests
//
//  Accessibility compatibility sweeps on isolated TestApp hosts (Issue #180).
//  Each test launches with a deep link argument so we validate framework behavior without launch-page navigation.
//

import XCTest

/// Per-test launch with ``DeepLink`` args; ``runAccessibilityCompatibilitySweep`` on the current screen only.
@MainActor
final class AccessibilityCompatibilityUITests: XCTestCase {

    private enum DeepLink: String {
        case control = "-OpenAccessibilityCompatibilityControlTest"
        case text = "-OpenAccessibilityCompatibilityTextTest"
        case button = "-OpenAccessibilityCompatibilityButtonTest"
        case platformPicker = "-OpenAccessibilityCompatibilityPlatformPickerTest"

        var navigationTitle: String {
            switch self {
            case .control: return "Control Test"
            case .text: return "Text Test"
            case .button: return "Button Test"
            case .platformPicker: return "Platform Picker Test"
            }
        }
    }

    private var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        addDefaultUIInterruptionMonitor()
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app?.terminate()
            instance.app = nil
        }
        try super.tearDownWithError()
    }

    private func launchForDeepLink(_ deepLink: DeepLink) {
        let localApp = XCUIApplication()
        localApp.configureForFastTesting()
        localApp.launchArguments.append(deepLink.rawValue)
        localApp.launch()
        XCTAssertTrue(
            localApp.navigationBars[deepLink.navigationTitle].waitForExistence(timeout: 10),
            "Deep link \(deepLink.rawValue) should show host with title \(deepLink.navigationTitle)"
        )
        app = localApp
    }

    func testControlTestView_CompatibilitySweep() throws {
        launchForDeepLink(.control)
        app.runAccessibilityCompatibilitySweep(screenLabel: DeepLink.control.navigationTitle)
    }

    func testTextTestView_CompatibilitySweep() throws {
        launchForDeepLink(.text)
        app.runAccessibilityCompatibilitySweep(screenLabel: DeepLink.text.navigationTitle)
    }

    func testPlatformPickerTestView_CompatibilitySweep() throws {
        launchForDeepLink(.platformPicker)
        app.runAccessibilityCompatibilitySweep(screenLabel: DeepLink.platformPicker.navigationTitle)
    }

    func testButtonTestView_CompatibilitySweep() throws {
        launchForDeepLink(.button)
        app.runAccessibilityCompatibilitySweep(screenLabel: DeepLink.button.navigationTitle)
    }
}
