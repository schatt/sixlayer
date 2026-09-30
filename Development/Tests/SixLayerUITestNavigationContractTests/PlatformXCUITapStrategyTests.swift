//
//  PlatformXCUITapStrategyTests.swift
//  SixLayerUITestNavigationContractTests
//
//  Call choice for XCUIElement.platformTap (#510).
//

import XCTest
import SixLayerFramework
@testable import SixLayerTestKit

final class PlatformTapCallTests: XCTestCase {

    func testIOSAndWatchOS_useTapAPI() {
        for platform in [SixLayerPlatform.iOS, .watchOS] {
            XCTAssertEqual(
                PlatformTapCall.plan(for: platform, numberOfTaps: 1, numberOfTouches: 1),
                .singleTap,
                "\(platform)"
            )
            XCTAssertEqual(
                PlatformTapCall.plan(for: platform, numberOfTaps: 2, numberOfTouches: 1),
                .tapWithNumberOfTaps(taps: 2, touches: 1),
                "\(platform)"
            )
            XCTAssertEqual(
                PlatformTapCall.plan(for: platform, numberOfTaps: 1, numberOfTouches: 2),
                .tapWithNumberOfTaps(taps: 1, touches: 2),
                "\(platform)"
            )
            XCTAssertEqual(
                PlatformTapCall.plan(for: platform, numberOfTaps: 3, numberOfTouches: 2),
                .tapWithNumberOfTaps(taps: 3, touches: 2),
                "\(platform)"
            )
        }
    }

    func testMacOS_clickOrDoubleClick_rejectsTheRest() {
        XCTAssertEqual(
            PlatformTapCall.plan(for: .macOS, numberOfTaps: 1, numberOfTouches: 1),
            .click
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .macOS, numberOfTaps: 2, numberOfTouches: 1),
            .doubleClick
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .macOS, numberOfTaps: 3, numberOfTouches: 1),
            .unsupported(.macOSTapCountAboveTwo)
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .macOS, numberOfTaps: 1, numberOfTouches: 2),
            .unsupported(.macOSMultipleTouches)
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .macOS, numberOfTaps: 2, numberOfTouches: 2),
            .unsupported(.macOSMultipleTouches)
        )
    }

    func testVisionOS_tapOrDoubleTap_rejectsTheRest() {
        XCTAssertEqual(
            PlatformTapCall.plan(for: .visionOS, numberOfTaps: 1, numberOfTouches: 1),
            .singleTap
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .visionOS, numberOfTaps: 2, numberOfTouches: 1),
            .doubleTap
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .visionOS, numberOfTaps: 3, numberOfTouches: 1),
            .unsupported(.visionOSTapCountAboveTwo)
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .visionOS, numberOfTaps: 1, numberOfTouches: 2),
            .unsupported(.visionOSMultipleTouches)
        )
    }

    func testTVOS_rejectsElementTap() {
        XCTAssertEqual(
            PlatformTapCall.plan(for: .tvOS, numberOfTaps: 1, numberOfTouches: 1),
            .unsupported(.tvOSElementTapUnavailable)
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .tvOS, numberOfTaps: 2, numberOfTouches: 2),
            .unsupported(.tvOSElementTapUnavailable)
        )
    }

    func testNonPositiveCounts_areTreatedAsOne() {
        XCTAssertEqual(
            PlatformTapCall.plan(for: .iOS, numberOfTaps: 0, numberOfTouches: 0),
            .singleTap
        )
        XCTAssertEqual(
            PlatformTapCall.plan(for: .macOS, numberOfTaps: -1, numberOfTouches: 1),
            .click
        )
    }
}
