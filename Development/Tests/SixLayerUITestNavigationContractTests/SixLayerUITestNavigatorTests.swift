//
//  SixLayerUITestNavigatorTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Unit coverage for SixLayerUITestNavigator primitives (#229); no hosted XCUIApplication.
//

import XCTest
@testable import SixLayerTestKit

final class SixLayerUITestNavigatorTests: XCTestCase {

    func testConsumeBackSteps_returnsZeroWhenMaxStepsIsZero() {
        var attempts = 0
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 0) {
            attempts += 1
            return true
        }
        XCTAssertEqual(count, 0)
        XCTAssertEqual(attempts, 0)
    }

    func testConsumeBackSteps_returnsZeroWhenMaxStepsNegative() {
        var attempts = 0
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: -1) {
            attempts += 1
            return true
        }
        XCTAssertEqual(count, 0)
        XCTAssertEqual(attempts, 0)
    }

    func testConsumeBackSteps_returnsZeroWhenFirstAttemptFails() {
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 5) { false }
        XCTAssertEqual(count, 0)
    }

    func testConsumeBackSteps_countsSuccessfulAttemptsUntilFailure() {
        var remainingTrue = 3
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 10) {
            if remainingTrue > 0 {
                remainingTrue -= 1
                return true
            }
            return false
        }
        XCTAssertEqual(count, 3)
    }

    func testConsumeBackSteps_respectsMaxStepsCap() {
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 4) { true }
        XCTAssertEqual(count, 4)
    }

    func testBackToRoot_forwardsToBackAttemptOverride() {
        var backs = 0
        let app = XCUIApplication()
        let navigator = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, _, _ in nil },
            backAttemptOverride: {
                backs += 1
                return backs < 3
            }
        )
        XCTAssertEqual(navigator.backToRoot(maxSteps: 10, stepTimeout: 0.01), 2)
        XCTAssertEqual(backs, 3)
    }

    func testGoToScreen_returnsFalseWhenFinderReturnsNil() throws {
        let app = XCUIApplication()
        let screen = try UITestScreenId(validating: "contract.screen.one")
        let navigator = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, _, _ in nil }
        )
        XCTAssertFalse(navigator.goToScreen(screen, timeout: 0.01))
    }

    func testOpenSection_returnsFalseWhenFinderReturnsNil() throws {
        let app = XCUIApplication()
        let route = try UITestRouteId(validating: "section.main")
        let navigator = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, _, _ in nil }
        )
        XCTAssertFalse(navigator.openSection(route, under: nil, timeout: 0.01))
    }

    func testFindContractElement_returnsNilWhenFinderReturnsNil() throws {
        let app = XCUIApplication()
        let elementId = try UITestElementId(validating: "control.example")
        let navigator = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { _, _, _ in nil }
        )
        XCTAssertNil(navigator.findContractElement(elementId, under: nil))
    }

    func testFindContractElement_passesApplicationRootWhenUnderIsNil() throws {
        let app = XCUIApplication()
        var capturedRoot: XCUIElement?
        let elementId = try UITestElementId(validating: "control.example")
        let navigator = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { root, _, _ in
                capturedRoot = root
                return nil
            }
        )
        _ = navigator.findContractElement(elementId, under: nil)
        XCTAssertTrue(capturedRoot === app)
    }

    func testFindContractElement_passesExplicitRootToFinder() throws {
        let app = XCUIApplication()
        let subtree = app.descendants(matching: .any).firstMatch
        var capturedRoot: XCUIElement?
        let elementId = try UITestElementId(validating: "control.example")
        let navigator = SixLayerUITestNavigator(
            application: app,
            findFirstExisting: { root, _, _ in
                capturedRoot = root
                return nil
            }
        )
        _ = navigator.findContractElement(elementId, under: subtree)
        XCTAssertTrue(capturedRoot === subtree)
    }
}
