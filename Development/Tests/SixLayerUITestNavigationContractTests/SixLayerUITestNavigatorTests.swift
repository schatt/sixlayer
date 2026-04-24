//
//  SixLayerUITestNavigatorTests.swift
//  SixLayerUITestNavigationContractTests
//
//  SixLayerUITestNavigator primitives (#229).
//

import XCTest
@testable import SixLayerTestKit

final class SixLayerUITestNavigatorTests: XCTestCase {

    func testConsumeBackSteps_invokesAttemptUntilFalse() {
        var remaining = 3
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 10) {
            if remaining == 0 { return false }
            remaining -= 1
            return true
        }
        XCTAssertEqual(count, 3)
    }

    func testConsumeBackSteps_respectsMaxSteps() {
        var calls = 0
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 2) {
            calls += 1
            return true
        }
        XCTAssertEqual(count, 2)
        XCTAssertEqual(calls, 2)
    }

    func testFindContractElement_forwardsToInjectedFinder() throws {
        let app = XCUIApplication()
        let id = try UITestElementId(validating: "com.example.widget")
        var capturedRoot: XCUIElement?
        var capturedId: UITestElementId?
        var capturedCfg: UITestContractElementResolverConfiguration?

        let nav = SixLayerUITestNavigator(application: app, resolverConfiguration: UITestContractElementResolverConfiguration(timeoutPerSlot: 0.42)) { root, elementId, cfg in
            capturedRoot = root
            capturedId = elementId
            capturedCfg = cfg
            return nil
        }

        let result = nav.findContractElement(id)
        XCTAssertNil(result)
        XCTAssertTrue(capturedRoot === app)
        XCTAssertEqual(capturedId?.rawValue, id.rawValue)
        XCTAssertEqual(capturedCfg?.timeoutPerSlot, 0.42)
    }

    func testGoToScreen_usesFinderWithScreenRawValue() throws {
        let app = XCUIApplication()
        let screen = try UITestScreenId(validating: "com.example.screen")
        var resolved: String?
        let nav = SixLayerUITestNavigator(application: app) { _, elementId, _ in
            resolved = elementId.rawValue
            return nil
        }
        XCTAssertFalse(nav.goToScreen(screen, timeout: 1.0))
        XCTAssertEqual(resolved, screen.rawValue)
    }

    func testOpenSection_usesFinderWithRouteRawValue() throws {
        let app = XCUIApplication()
        let route = try UITestRouteId(validating: "com.example.section")
        var resolved: String?
        let nav = SixLayerUITestNavigator(application: app) { _, elementId, _ in
            resolved = elementId.rawValue
            return nil
        }
        XCTAssertFalse(nav.openSection(route, timeout: 1.0))
        XCTAssertEqual(resolved, route.rawValue)
    }
}
