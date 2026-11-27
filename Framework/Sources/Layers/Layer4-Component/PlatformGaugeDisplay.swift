//
//  PlatformGaugeDisplay.swift
//  SixLayerFramework
//
//  Shared, non-trapping gauge resolution and whole-number text (#710).
//

import Foundation

/// Shown in place of a numeric value that is NaN or infinite (an em dash).
let platformNonFiniteNumberText = "\u{2014}"

/// Whole-number text for a numeric control or label. Never converts to `Int`:
/// `Int(Double)` traps on NaN, infinity, and finite values outside `Int` range (#562, #710).
/// Non-finite values show an em dash; others round to the nearest whole number.
func platformWholeNumberText(_ value: Double) -> String {
    guard value.isFinite else { return platformNonFiniteNumberText }
    let rounded = value.rounded()
    // `rounded == 0` normalizes -0.0 (and values that round to it) so labels never show "-0".
    return String(format: "%.0f", rounded == 0 ? 0 : rounded)
}

/// Everything a gauge surface needs, resolved once so `platformGaugeInput` and
/// `DynamicGaugeField` cannot drift (#710).
///
/// - Bounds: a non-finite bound falls back per bound to ``defaultLowerBound`` /
///   ``defaultUpperBound``; inverted bounds are ordered (same policy as the #562 stepper),
///   so `ClosedRange` construction never traps.
/// - Value: a non-finite value is drawn at the lower bound and labeled with an em dash.
struct PlatformGaugeDisplay: Equatable {
    static let defaultLowerBound = 0.0
    static let defaultUpperBound = 100.0

    let range: ClosedRange<Double>
    let value: Double
    let valueText: String
    let minText: String
    let maxText: String

    init(value: Double, min: Double, max: Double) {
        let lower = min.isFinite ? min : Self.defaultLowerBound
        let upper = max.isFinite ? max : Self.defaultUpperBound
        let range = ClosedRange<Double>.ordered(lower, upper)
        self.range = range
        self.value = value.isFinite ? value : range.lowerBound
        self.valueText = platformWholeNumberText(value)
        self.minText = platformWholeNumberText(range.lowerBound)
        self.maxText = platformWholeNumberText(range.upperBound)
    }
}
