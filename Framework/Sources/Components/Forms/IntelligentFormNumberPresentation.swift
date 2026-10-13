//
//  IntelligentFormNumberPresentation.swift
//  SixLayerFramework
//
//  Keyboard and stepper bounds for IntelligentFormView number fields (Issue #550).
//

import Foundation

/// Pure presentation choices for an IntelligentFormView number field.
public enum IntelligentFormNumberPresentation {
    /// Historical unsigned stepper ceiling when no `expectedRange` is set.
    public static let unsignedStepperUpperBound: Double = 1000

    /// Same keyboard choice as `DynamicNumberField`: decimal pad unless negatives are allowed.
    public static func keyboardType(allowsNegative: Bool) -> PlatformKeyboardType {
        NumericFieldKeyboard.keyboardType(kind: .number, allowsNegative: allowsNegative)
    }

    /// `expectedRange` wins. Otherwise a signed field uses `-1000...1000` and an unsigned field keeps `0...1000`.
    public static func stepperRange(hints: FieldDisplayHints?) -> ClosedRange<Double> {
        if let expected = hints?.expectedRange {
            let lower = min(expected.min, expected.max)
            let upper = max(expected.min, expected.max)
            return lower...upper
        }
        if hints?.allowsNegative == true {
            return (-unsignedStepperUpperBound)...unsignedStepperUpperBound
        }
        return 0...unsignedStepperUpperBound
    }
}
