//
//  SaturatingIntegerConversionTests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #711: `Int(Double)` / `Int64(Double)` trap on NaN, infinity, and finite
//  values outside the integer range. `init?(saturatingTruncating:)` is the shared,
//  non-trapping conversion: NaN has no integer value (nil), everything else
//  truncates toward zero and saturates at the type's bounds.
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Saturating integer conversion (#711)")
struct SaturatingIntegerConversionTests {

    @Test func nanHasNoIntegerValue() {
        #expect(Int(saturatingTruncating: .nan) == nil)
        #expect(Int64(saturatingTruncating: .nan) == nil)
        #expect(UInt8(saturatingTruncating: .nan) == nil)
    }

    @Test func infinitySaturatesAtTheTypeBounds() {
        #expect(Int(saturatingTruncating: .infinity) == Int.max)
        #expect(Int(saturatingTruncating: -.infinity) == Int.min)
        #expect(Int64(saturatingTruncating: .infinity) == Int64.max)
        #expect(Int64(saturatingTruncating: -.infinity) == Int64.min)
    }

    @Test func finiteOutOfRangeValuesSaturate() {
        #expect(Int64(saturatingTruncating: 1e30) == Int64.max)
        #expect(Int64(saturatingTruncating: -1e30) == Int64.min)
        // 2^63 is the first Double above Int64.max; it must saturate, not trap.
        #expect(Int64(saturatingTruncating: 9_223_372_036_854_775_808.0) == Int64.max)
    }

    @Test func inRangeValuesTruncateTowardZero() {
        #expect(Int(saturatingTruncating: 3.9) == 3)
        #expect(Int(saturatingTruncating: -3.9) == -3)
        #expect(Int(saturatingTruncating: 0.5) == 0)
        #expect(Int(saturatingTruncating: -0.5) == 0)
        #expect(Int(saturatingTruncating: 12) == 12)
    }

    @Test func narrowTypesSaturateAtTheirOwnBounds() {
        #expect(Int8(saturatingTruncating: 200) == Int8.max)
        #expect(Int8(saturatingTruncating: -200) == Int8.min)
        #expect(UInt8(saturatingTruncating: 300) == UInt8.max)
        #expect(UInt8(saturatingTruncating: -5) == UInt8.min)
        #expect(UInt8(saturatingTruncating: 255.9) == 255)
    }
}
