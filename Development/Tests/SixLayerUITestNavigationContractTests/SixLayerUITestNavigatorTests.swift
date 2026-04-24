//
//  SixLayerUITestNavigatorTests.swift
//  SixLayerUITestNavigationContractTests
//
//  SixLayerUITestNavigator primitives (#229).
//

import XCTest
@testable import SixLayerTestKit

final class SixLayerUITestNavigatorTests: XCTestCase {

    /// Prefer a real system app bundle so `XCUIApplication` does not require a UI-test host `TEST_HOST` path.
    private func makeReferenceApplication() -> XCUIApplication {
        #if os(macOS)
        XCUIApplication(bundleIdentifier: "com.apple.finder")
        #else
        XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        #endif
    }

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
        let app = makeReferenceApplication()
        let id = try UITestElementId(validating: "com.example.widget")
        var capturedRoot: XCUIElement?
        var capturedId: UITestElementId?
        var capturedCfg: UITestContractElementResolverConfiguration?

        let nav = SixLayerUITestNavigator(
            application: app,
            resolverConfiguration: UITestContractElementResolverConfiguration(timeoutPerSlot: 0.42),
            findFirstExisting: { root, elementId, cfg in
                capturedRoot = root
                capturedId = elementId
                capturedCfg = cfg
                return nil
            },
            backAttemptOverride: nil
        )

        let result = nav.findContractElement(id)
        XCTAssertNil(result)
        XCTAssertTrue(capturedRoot === app)
        XCTAssertEqual(capturedId?.rawValue, id.rawValue)
        XCTAssertEqual(capturedCfg?.timeoutPerSlot, 0.42)
    }

    func testGoToScreen_usesFinderWithScreenRawValue() throws {
        let app = makeReferenceApplication()
        let screen = try UITestScreenId(validating: "com.example.screen")
        var resolved: String?
        let nav = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, elementId, _ in
                resolved = elementId.rawValue
                return nil
            },
            backAttemptOverride: nil
        )
        XCTAssertFalse(nav.goToScreen(screen, timeout: 1.0))
        XCTAssertEqual(resolved, screen.rawValue)
    }

    func testOpenSection_usesFinderWithRouteRawValue() throws {
        let app = makeReferenceApplication()
        let route = try UITestRouteId(validating: "com.example.section")
        var resolved: String?
        let nav = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, elementId, _ in
                resolved = elementId.rawValue
                return nil
            },
            backAttemptOverride: nil
        )
        XCTAssertFalse(nav.openSection(route, timeout: 1.0))
        XCTAssertEqual(resolved, route.rawValue)
    }

    func testBackToRoot_countsSyntheticAttempts() {
        let app = makeReferenceApplication()
        var wave = 0
        let nav = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, _, _ in nil },
            backAttemptOverride: {
                wave += 1
                return wave < 4
            }
        )
        XCTAssertEqual(nav.backToRoot(maxSteps: 10, stepTimeout: 0.01), 3)
    }
}
