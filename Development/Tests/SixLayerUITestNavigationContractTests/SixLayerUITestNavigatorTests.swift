//
//  SixLayerUITestNavigatorTests.swift
//  SixLayerUITestNavigationContractTests
//
//  SixLayerUITestNavigator primitives (#229).
//
//  Note: `XCUIApplication` / XCUI queries are not supported in SwiftPM **unit** test bundles
//  ("Device is not configured for UI testing"). Injection and host flows are covered in UI test
//  targets (#231) and by `SixLayerUITestNavigatorInternals` here.
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

    func testConsumeBackSteps_returnsZeroWhenFirstAttemptFails() {
        let count = SixLayerUITestNavigatorInternals.consumeBackSteps(maxSteps: 5) { false }
        XCTAssertEqual(count, 0)
    }
}
