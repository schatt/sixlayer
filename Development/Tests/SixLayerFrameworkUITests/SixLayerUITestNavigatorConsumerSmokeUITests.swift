//
//  SixLayerUITestNavigatorConsumerSmokeUITests.swift
//  SixLayerFrameworkUITests
//
//  Consumer-style smoke for SixLayerUITestNavigator + UITestContractAssertions (#231, #230).
//  Requires TestApp launched with `-OpenUITestContractSmokeHost` (see UITestContractSmokeHostView).
//

import XCTest
import SixLayerTestKit

@MainActor
final class SixLayerUITestNavigatorConsumerSmokeUITests: XCTestCase {

    private var app: XCUIApplication!

    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            let localApp = XCUIApplication()
            localApp.configureForFastTesting()
            localApp.launchArguments.append("-OpenUITestContractSmokeHost")
            localApp.launch()
            instance.app = localApp
            let marker = localApp.descendants(matching: .any).matching(identifier: "com.sixlayer.smoke.ready.marker").element
            XCTAssertTrue(marker.waitForExistence(timeout: 8), "Smoke host ready marker should appear")
        }
    }

    nonisolated override func tearDownWithError() throws {
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            instance.app = nil
        }
    }

    @MainActor
    func testSmoke_findContractElement_resolvesReadyMarker() throws {
        let navigator = SixLayerUITestNavigator(application: app)
        let id = try UITestElementId(validating: "com.sixlayer.smoke.ready.marker")
        let resolved = navigator.findContractElement(id)
        XCTAssertNotNil(resolved)
        UITestContractAssertions.assertNonEmptyAccessibilityIdentifier(resolved!)
        // macOS SwiftUI often leaves `label` empty for static text; identifier is the contract surface we require.
    }

    @MainActor
    func testSmoke_goToScreenThenOpenSectionThenBackToRoot() throws {
        let navigator = SixLayerUITestNavigator(application: app)
        let screen = try UITestScreenId(validating: "com.sixlayer.smoke.screen.entry")
        XCTAssertTrue(navigator.goToScreen(screen, timeout: 15), "goToScreen should tap smoke entry control")

        let route = try UITestRouteId(validating: "com.sixlayer.smoke.route.section")
        XCTAssertTrue(navigator.openSection(route, under: nil, timeout: 15), "openSection should resolve detail marker")

        let backs = navigator.backToRoot(maxSteps: 8, stepTimeout: 5)
        XCTAssertGreaterThanOrEqual(backs, 1, "backToRoot should perform at least one successful pop")

        let markerId = try UITestElementId(validating: "com.sixlayer.smoke.ready.marker")
        XCTAssertNotNil(navigator.findContractElement(markerId), "Ready marker should be visible again at root")
    }
}
