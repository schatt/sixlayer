//
//  NumericFieldKeyboard.swift
//  SixLayerFramework
//
//  Keyboard choice for DynamicNumberField and DynamicIntegerField (Issue #548).
//

import Foundation

/// Number versus integer text fields. Each has its own pad when negatives are off.
public enum NumericFieldKind: String, Sendable, Equatable {
    case number
    case integer
}

/// Pure keyboard selection for signed and unsigned numeric fields.
public enum NumericFieldKeyboard {
    /// Off keeps the numeric pad for the field kind. On uses the only stock keyboard that includes a minus.
    public static func keyboardType(kind: NumericFieldKind, allowsNegative: Bool) -> PlatformKeyboardType {
        if allowsNegative {
            return .numbersAndPunctuation
        }
        switch kind {
        case .number:
            return .decimalPad
        case .integer:
            return .numberPad
        }
    }
}
