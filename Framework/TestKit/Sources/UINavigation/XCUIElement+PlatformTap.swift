//
//  XCUIElement+PlatformTap.swift
//  SixLayerTestKit
//
//  Cross-platform XCUI tap (#510). Deliberate-red stub: plan() still encodes the
//  shipped mapping so PlatformTapCallTests fail for that reason.
//

import Foundation
import SixLayerFramework

#if canImport(XCTest)
import XCTest

/// Why ``XCUIElement/platformTap(numberOfTaps:numberOfTouches:)`` cannot perform the request.
public enum PlatformTapRejection: String, Equatable, Sendable {
    case tvOSElementTapUnavailable
    case macOSTapCountAboveTwo
    case macOSMultipleTouches
    case visionOSTapCountAboveTwo
    case visionOSMultipleTouches
}

/// XCUI call chosen for ``XCUIElement/platformTap(numberOfTaps:numberOfTouches:)``.
public enum PlatformTapCall: Equatable, Sendable {
    case singleTap
    case tapWithNumberOfTaps(taps: Int, touches: Int)
    case click
    case doubleClick
    case doubleTap
    case unsupported(PlatformTapRejection)

    /// Shipped #510 mapping, kept wrong on purpose until the green implementation.
    public static func plan(
        for platform: SixLayerPlatform,
        numberOfTaps: Int,
        numberOfTouches: Int
    ) -> PlatformTapCall {
        let taps = max(numberOfTaps, 1)
        let touches = max(numberOfTouches, 1)
        switch platform {
        case .iOS, .tvOS, .visionOS:
            if taps == 1, touches == 1 {
                return .singleTap
            }
            return .tapWithNumberOfTaps(taps: taps, touches: touches)
        case .macOS:
            return .click
        case .watchOS:
            return .singleTap
        }
    }
}

public extension XCUIElement {
    func platformTap(numberOfTaps: Int = 1, numberOfTouches: Int = 1) {
        let taps = max(numberOfTaps, 1)
        for _ in 0..<taps {
            #if os(macOS)
            click()
            #elseif os(tvOS)
            break
            #else
            tap()
            #endif
        }
    }
}
#endif
