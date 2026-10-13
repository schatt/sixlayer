import Foundation
import SwiftUI

/// Formats values stored in ``DynamicFormState`` for numeric text fields (`DynamicNumberField`, `DynamicIntegerField`).
///
/// **Read contract:** `String` is shown as-is; `Int`, `Double`, and `NSNumber` are formatted for display without
/// scientific notation for typical magnitudes. **Write contract:** fields continue to store `String` from the text binding.
///
/// This is separate from draft persistence keys (``DynamicFormState`` `draftStorageKey`, Issue #273).
public enum DynamicFormStoredNumericDisplay {

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 10
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Display string for a stored field value, falling back to `defaultValue` then `""`.
    public static func displayString(fromStoredValue value: Any?, defaultValue: String? = nil) -> String {
        guard let value else {
            return defaultValue ?? ""
        }

        if let string = value as? String {
            return string
        }

        if let intValue = value as? Int {
            return String(intValue)
        }

        if let doubleValue = value as? Double {
            return formatDouble(doubleValue)
        }

        if let number = value as? NSNumber {
            return formatNSNumber(number)
        }

        return defaultValue ?? ""
    }

    private static func formatNSNumber(_ number: NSNumber) -> String {
        if CFNumberIsFloatType(number) {
            return formatDouble(number.doubleValue)
        }
        return number.stringValue
    }

    private static func formatDouble(_ value: Double) -> String {
        guard value.isFinite else {
            return String(value)
        }

        let rounded = value.rounded()
        if abs(value - rounded) < 1e-9, abs(value) <= Double(Int.max) {
            return String(Int(rounded))
        }

        return decimalFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// True when `newValue` is a sibling text field echoing a stale string over a stored number (#558).
    /// A focused field always accepts the write. A stored `String` always accepts the write.
    /// The same number as the stored value is a display refresh and is kept.
    static func shouldIgnoreNumericBindingSet(
        newValue: String,
        storedValue: Any?,
        fieldIsFocused: Bool
    ) -> Bool {
        if fieldIsFocused { return false }
        guard let storedNumber = storedNumber(storedValue) else { return false }
        if let incoming = parsedNumber(newValue), numbersEqual(incoming, storedNumber) {
            return false
        }
        return true
    }

    private static func storedNumber(_ value: Any?) -> Double? {
        switch value {
        case let double as Double:
            return double.isFinite ? double : nil
        case let int as Int:
            return Double(int)
        case let number as NSNumber:
            let double = number.doubleValue
            return double.isFinite ? double : nil
        default:
            return nil
        }
    }

    private static func parsedNumber(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let cleaned = trimmed
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleaned).flatMap { $0.isFinite ? $0 : nil }
    }

    private static func numbersEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= 0.000_000_1 * max(1, abs(rhs))
    }
}

@MainActor
extension DynamicFormField {
    /// Text binding that reads numeric stored values as display strings and writes `String`.
    ///
    /// A sibling field can push the string still on screen when another field's value changes.
    /// That echo must not replace a stored number unless this field is focused (#558).
    func numericTextBinding(formState: DynamicFormState) -> Binding<String> {
        Binding(
            get: {
                DynamicFormStoredNumericDisplay.displayString(
                    fromStoredValue: formState.getValue(for: id),
                    defaultValue: defaultValue
                )
            },
            set: { newValue in
                if DynamicFormStoredNumericDisplay.shouldIgnoreNumericBindingSet(
                    newValue: newValue,
                    storedValue: formState.getValue(for: id),
                    fieldIsFocused: formState.focusedFieldId == id
                ) {
                    return
                }
                formState.setValue(newValue, for: id)
            }
        )
    }
}
