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
    /// Deliberate stub: always the decimal pad so tests fail until the matrix is implemented.
    public static func keyboardType(kind: NumericFieldKind, allowsNegative: Bool) -> PlatformKeyboardType {
        _ = kind
        _ = allowsNegative
        return .decimalPad
    }
}
