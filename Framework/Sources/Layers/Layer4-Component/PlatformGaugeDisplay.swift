//
//  PlatformGaugeDisplay.swift
//  SixLayerFramework
//
//  Shared, non-trapping gauge resolution and whole-number text (#710).
//

import Foundation

/// STUB for the #710 red run: returns wrong values so the new tests fail at runtime.
func platformWholeNumberText(_ value: Double) -> String {
    ""
}

/// STUB for the #710 red run.
struct PlatformGaugeDisplay: Equatable {
    let range: ClosedRange<Double>
    let value: Double
    let valueText: String
    let minText: String
    let maxText: String

    init(value: Double, min: Double, max: Double) {
        self.range = 0...0
        self.value = 0
        self.valueText = ""
        self.minText = ""
        self.maxText = ""
    }
}
