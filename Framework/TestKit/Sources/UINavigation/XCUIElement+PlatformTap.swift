//
//  XCUIElement+PlatformTap.swift
//  SixLayerTestKit
//
//  Cross-platform XCUI tap (#510). Call choice follows XCUIAutomation availability:
//  tap(withNumberOfTaps:numberOfTouches:) exists only for iOS and watchOS.
//

import Foundation
import SixLayerFramework

#if canImport(XCTest)
import XCTest

/// Why ``XCUIElement/platformTap(numberOfTaps:numberOfTouches:)`` cannot perform the request.
public enum PlatformTapRejection: String, Equatable, Sendable {
    /// `XCUIElement.tap` is `API_UNAVAILABLE` on tvOS. Use `XCUIRemote`.
    case tvOSElementTapUnavailable
    /// macOS has `click()` and `doubleClick()` only.
    case macOSTapCountAboveTwo
    /// macOS has no multi-touch XCUI tap.
    case macOSMultipleTouches
    /// visionOS has `tap()` and `doubleTap()` only. `tapWithNumberOfTaps` is not declared.
    case visionOSTapCountAboveTwo
    /// visionOS has no `tap(withNumberOfTaps:numberOfTouches:)`.
    case visionOSMultipleTouches

    var failureDescription: String {
        switch self {
        case .tvOSElementTapUnavailable:
            return "tvOS XCUIElement.tap is unavailable. Use XCUIRemote.press."
        case .macOSTapCountAboveTwo:
            return "macOS XCUI has click() and doubleClick() only. A tap count above 2 is not repeated clicks."
        case .macOSMultipleTouches:
            return "macOS XCUI has no multi-touch tap. numberOfTouches greater than 1 is unsupported."
        case .visionOSTapCountAboveTwo:
            return "visionOS XCUI has tap() and doubleTap() only. tap(withNumberOfTaps:) is not in the visionOS SDK."
        case .visionOSMultipleTouches:
            return "visionOS XCUI has no tap(withNumberOfTaps:numberOfTouches:). numberOfTouches greater than 1 is unsupported."
        }
    }
}

/// XCUI call ``XCUIElement/platformTap(numberOfTaps:numberOfTouches:)`` will make.
public enum PlatformTapCall: Equatable, Sendable {
    /// `XCUIElement.tap()` (iOS, watchOS, visionOS, one touch).
    case singleTap
    /// `tap(withNumberOfTaps:numberOfTouches:)` (iOS and watchOS).
    case tapWithNumberOfTaps(taps: Int, touches: Int)
    /// macOS `click()`.
    case click
    /// macOS `doubleClick()`.
    case doubleClick
    /// visionOS `doubleTap()`.
    case doubleTap
    /// The SDK cannot perform this request. ``platformTap`` fails the test.
    case unsupported(PlatformTapRejection)

    /// Counts below 1 are treated as 1.
    public static func plan(
        for platform: SixLayerPlatform,
        numberOfTaps: Int,
        numberOfTouches: Int
    ) -> PlatformTapCall {
        let taps = max(numberOfTaps, 1)
        let touches = max(numberOfTouches, 1)
        switch platform {
        case .iOS, .watchOS:
            if taps == 1, touches == 1 {
                return .singleTap
            }
            return .tapWithNumberOfTaps(taps: taps, touches: touches)
        case .macOS:
            if touches > 1 {
                return .unsupported(.macOSMultipleTouches)
            }
            if taps > 2 {
                return .unsupported(.macOSTapCountAboveTwo)
            }
            return taps == 2 ? .doubleClick : .click
        case .visionOS:
            if touches > 1 {
                return .unsupported(.visionOSMultipleTouches)
            }
            if taps > 2 {
                return .unsupported(.visionOSTapCountAboveTwo)
            }
            return taps == 2 ? .doubleTap : .singleTap
        case .tvOS:
            return .unsupported(.tvOSElementTapUnavailable)
        }
    }
}

public extension XCUIElement {
    /// Cross-platform element activation for XCUI tests (#510 / CarManager #1119).
    ///
    /// The call is ``PlatformTapCall/plan(for:numberOfTaps:numberOfTouches:)`` for
    /// ``SixLayerPlatform/current``. Unsupported combinations fail the test instead of
    /// repeating a single click or tap.
    ///
    /// - iOS / watchOS: `tap(withNumberOfTaps:numberOfTouches:)`, or `tap()` when both counts are 1.
    /// - macOS: `click()` or `doubleClick()`. SwiftUI on macOS ignores `tap()` (#516).
    /// - visionOS: `tap()` or `doubleTap()`.
    /// - tvOS: fails. Use `XCUIRemote`.
    func platformTap(numberOfTaps: Int = 1, numberOfTouches: Int = 1) {
        switch PlatformTapCall.plan(
            for: SixLayerPlatform.current,
            numberOfTaps: numberOfTaps,
            numberOfTouches: numberOfTouches
        ) {
        case .singleTap:
            platformPerformSingleTap()
        case .tapWithNumberOfTaps(let taps, let touches):
            platformPerformMultiTap(numberOfTaps: taps, numberOfTouches: touches)
        case .click:
            platformPerformClick()
        case .doubleClick:
            platformPerformDoubleClick()
        case .doubleTap:
            platformPerformDoubleTap()
        case .unsupported(let reason):
            XCTFail(reason.failureDescription)
        }
    }

    private func platformPerformSingleTap() {
        #if os(tvOS)
        XCTFail(PlatformTapRejection.tvOSElementTapUnavailable.failureDescription)
        #else
        performPreferringHittable(element: { tap() }, center: { $0.tap() })
        #endif
    }

    private func platformPerformMultiTap(numberOfTaps: Int, numberOfTouches: Int) {
        // visionOS before iOS: some SDKs treat visionOS as os(iOS), and visionOS has no multi-tap method.
        #if os(visionOS)
        XCTFail(PlatformTapRejection.visionOSMultipleTouches.failureDescription)
        #elseif os(iOS) || os(watchOS)
        tap(withNumberOfTaps: numberOfTaps, numberOfTouches: numberOfTouches)
        #else
        XCTFail("tap(withNumberOfTaps:numberOfTouches:) is not available on this platform")
        #endif
    }

    private func platformPerformClick() {
        #if os(macOS)
        performPreferringHittable(element: { click() }, center: { $0.click() })
        #else
        XCTFail("click() is only the macOS platformTap path")
        #endif
    }

    private func platformPerformDoubleClick() {
        #if os(macOS)
        performPreferringHittable(element: { doubleClick() }, center: { $0.doubleClick() })
        #else
        XCTFail("doubleClick() is only the macOS platformTap path")
        #endif
    }

    private func platformPerformDoubleTap() {
        #if os(visionOS)
        performPreferringHittable(element: { doubleTap() }, center: { $0.doubleTap() })
        #elseif os(tvOS)
        XCTFail(PlatformTapRejection.tvOSElementTapUnavailable.failureDescription)
        #else
        XCTFail("doubleTap() is only the visionOS platformTap path")
        #endif
    }

    private func performPreferringHittable(
        element: () -> Void,
        center: (XCUICoordinate) -> Void
    ) {
        if isHittable {
            element()
            return
        }
        if let usableCenter = platformCenterCoordinateIfUsable() {
            center(usableCenter)
        } else {
            element()
        }
    }

    private func platformCenterCoordinateIfUsable() -> XCUICoordinate? {
        let elementFrame = frame
        let usable = elementFrame.width.isFinite && elementFrame.height.isFinite
            && elementFrame.origin.x.isFinite && elementFrame.origin.y.isFinite
            && elementFrame.width > 0 && elementFrame.height > 0
        guard usable else { return nil }
        return coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    }
}
#endif
