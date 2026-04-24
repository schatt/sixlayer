//
//  SixLayerUITestNavigatorTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Pure Swift coverage for SixLayerUITestNavigator back-step policy (#229).
//  Do not construct XCUIApplication here: SPM XCTest has no UI test host, which traps.
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
}
