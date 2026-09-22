//
//  XCUIElement+PlatformTap.swift
//  SixLayerTestKit
//
//  Cross-platform XCUI multi-tap (#510). iOS-only
//  `tap(withNumberOfTaps:numberOfTouches:)` does not compile on macOS.
//

import Foundation
import SixLayerFramework

#if canImport(XCTest)
import XCTest

/// How ``XCUIElement/platformTap(numberOfTaps:numberOfTouches:)`` performs a multi-tap.
///
/// API availability is compile-time (`#if os`); this type documents the runtime strategy
/// keyed by ``SixLayerPlatform`` for tests and call-site clarity.
public enum PlatformXCUITapStrategy: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Call `tap(withNumberOfTaps:numberOfTouches:)` (iOS / tvOS / visionOS).
    case multiTapAPI
    /// No multi-tap XCUI API — repeat single `tap()` / coordinate fallback (macOS / watchOS).
    case repeatedSingleTap

    /// Strategy for a given SixLayer platform.
    public static func forPlatform(_ platform: SixLayerPlatform) -> PlatformXCUITapStrategy {
        switch platform {
        case .iOS, .tvOS, .visionOS:
            return .multiTapAPI
        case .macOS, .watchOS:
            return .repeatedSingleTap
        }
    }

    /// Strategy for the compile-time current platform.
    public static var current: PlatformXCUITapStrategy {
        forPlatform(SixLayerPlatform.current)
    }
}

public extension XCUIElement {
    /// Cross-platform tap. Prefer this over iOS-only `tap(withNumberOfTaps:numberOfTouches:)`.
    ///
    /// - On iOS / tvOS / visionOS: uses `tap(withNumberOfTaps:numberOfTouches:)` when either
    ///   count is greater than 1; otherwise a single `tap()`.
    /// - On macOS / watchOS: repeats a single tap (or center coordinate when not hittable)
    ///   `numberOfTaps` times. `numberOfTouches` is ignored (no multi-touch XCUI API).
    ///
    /// Strategy: ``PlatformXCUITapStrategy/current`` (#510 / CarManager #1119).
    func platformTap(numberOfTaps: Int = 1, numberOfTouches: Int = 1) {
        let taps = max(numberOfTaps, 1)
        let touches = max(numberOfTouches, 1)
        switch PlatformXCUITapStrategy.current {
        case .multiTapAPI:
            #if os(iOS) || os(tvOS) || os(visionOS)
            if taps == 1, touches == 1 {
                tap()
            } else {
                tap(withNumberOfTaps: taps, numberOfTouches: touches)
            }
            #else
            // Unreachable when Strategy.current matches compile platform; keep macOS compiling.
            platformTapRepeatedSingle(taps: taps)
            #endif
        case .repeatedSingleTap:
            platformTapRepeatedSingle(taps: taps)
        }
    }

    private func platformTapRepeatedSingle(taps: Int) {
        for _ in 0..<taps {
            platformTapOncePreferringHittable()
        }
    }

    private func platformTapOncePreferringHittable() {
        #if os(macOS)
        // SwiftUI presentation/navigation needs click on macOS; tap alone is a no-op (#516 / #518).
        if isHittable {
            click()
            return
        }
        let frame = frame
        let valid = frame.width.isFinite && frame.height.isFinite
            && frame.origin.x.isFinite && frame.origin.y.isFinite
            && frame.width > 0 && frame.height > 0
        if valid {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        } else {
            click()
        }
        #else
        if isHittable {
            tap()
            return
        }
        let frame = frame
        let valid = frame.width.isFinite && frame.height.isFinite
            && frame.origin.x.isFinite && frame.origin.y.isFinite
            && frame.width > 0 && frame.height > 0
        if valid {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            tap()
        }
        #endif
    }
}
#endif
