//
//  PlatformXCUITapStrategyTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Platform → multi-tap strategy mapping for XCUIElement.platformTap (#510).
//

import XCTest
import SixLayerFramework
@testable import SixLayerTestKit

final class PlatformXCUITapStrategyTests: XCTestCase {

    func testForPlatform_mapsTouchPlatformsToMultiTapAPI() {
        XCTAssertEqual(PlatformXCUITapStrategy.forPlatform(.iOS), .multiTapAPI)
        XCTAssertEqual(PlatformXCUITapStrategy.forPlatform(.tvOS), .multiTapAPI)
        XCTAssertEqual(PlatformXCUITapStrategy.forPlatform(.visionOS), .multiTapAPI)
    }

    func testForPlatform_mapsMacAndWatchToRepeatedSingleTap() {
        XCTAssertEqual(PlatformXCUITapStrategy.forPlatform(.macOS), .repeatedSingleTap)
        XCTAssertEqual(PlatformXCUITapStrategy.forPlatform(.watchOS), .repeatedSingleTap)
    }

    func testCurrent_matchesCompileTimePlatform() {
        XCTAssertEqual(
            PlatformXCUITapStrategy.current,
            PlatformXCUITapStrategy.forPlatform(SixLayerPlatform.current)
        )
    }

    func testAllCases_coverDocumentedStrategies() {
        XCTAssertEqual(
            Set(PlatformXCUITapStrategy.allCases),
            [.multiTapAPI, .repeatedSingleTap]
        )
    }
}
