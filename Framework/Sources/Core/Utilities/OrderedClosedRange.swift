//
//  OrderedClosedRange.swift
//  SixLayerFramework
//
//  One ordering rule for numeric control bounds (#562 stepper, #710 gauge).
//

import Foundation

extension ClosedRange where Bound == Double {
    /// The range spanning `a` and `b` in either order.
    ///
    /// `ClosedRange` construction traps when the lower bound exceeds the upper bound or either
    /// is NaN, so callers must pass **finite** bounds (sanitize first); this only removes the
    /// ordering hazard.
    static func ordered(_ a: Double, _ b: Double) -> ClosedRange<Double> {
        Swift.min(a, b)...Swift.max(a, b)
    }
}
