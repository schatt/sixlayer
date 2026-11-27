//
//  SaturatingIntegerConversion.swift
//  SixLayerFramework
//
//  Non-trapping Double -> integer conversion (#711).
//

import Foundation

extension FixedWidthInteger {
    /// Converts `value` to an integer without ever trapping.
    ///
    /// `Int(_: Double)` and `Int64(_: Double)` trap on NaN, infinity, and finite values
    /// outside the integer range, so one bad measurement can abort the process.
    ///
    /// - NaN has no integer value: returns `nil`.
    /// - Otherwise the value is truncated toward zero (same as `Int(_:)`), and values
    ///   outside the type's range - including +/-infinity - saturate at `min` / `max`.
    init?(saturatingTruncating value: Double) {
        guard !value.isNaN else { return nil }
        if let exact = Self(exactly: value.rounded(.towardZero)) {
            self = exact
        } else {
            self = value < 0 ? Self.min : Self.max
        }
    }
}
