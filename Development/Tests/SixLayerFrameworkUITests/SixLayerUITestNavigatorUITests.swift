//
//  SixLayerUITestNavigatorUITests.swift
//  SixLayerFrameworkUITests
//
//  UI-target tests for SixLayerUITestNavigator primitives (#229).
//

import XCTest
#if canImport(SixLayerTestKit)
import SixLayerTestKit

@MainActor
final class SixLayerUITestNavigatorUITests: XCTestCase {
    func testBackToRoot_returnsZeroWhenMaxStepsIsZero() {
        let app = XCUIApplication()
        let navigator = SixLayerUITestNavigator(application: app)
        XCTAssertEqual(navigator.backToRoot(maxSteps: 0), 0)
    }

    func testGoToScreen_returnsFalseWhenContractElementIsMissing() throws {
        let app = XCUIApplication()
        let navigator = SixLayerUITestNavigator(application: app)
        let screen = try UITestScreenId(validating: "contract.missing.screen")
        XCTAssertFalse(navigator.goToScreen(screen, timeout: 0.01))
    }
}
#endif
