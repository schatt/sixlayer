//
//  IntelligentFormNumberPresentation.swift
//  SixLayerFramework
//
//  Keyboard and stepper bounds for IntelligentFormView number fields (Issue #550).
//

import Foundation

/// Pure presentation choices for an IntelligentFormView number field.
public enum IntelligentFormNumberPresentation {
    /// Stub: historical unsigned keyboard. Tests expect a signed opt-in.
    public static func keyboardType(allowsNegative: Bool) -> PlatformKeyboardType {
        _ = allowsNegative
        return .decimalPad
    }

    /// Stub: historical stepper bounds. Tests expect hints to widen them.
    public static func stepperRange(hints: FieldDisplayHints?) -> ClosedRange<Double> {
        _ = hints
        return 0...1000
    }
}
