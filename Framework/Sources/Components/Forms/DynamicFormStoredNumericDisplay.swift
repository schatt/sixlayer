import Foundation
import SwiftUI

/// Formats values stored in ``DynamicFormState`` for numeric text fields (`DynamicNumberField`, `DynamicIntegerField`).
///
/// **Read contract:** `String` is shown as-is; `Int`, `Double`, and `NSNumber` are formatted for display without
/// scientific notation for typical magnitudes. **Write contract:** a focused field stores `String`. An unfocused
/// write replaces a stored `String`. It does not replace a stored number, including with that number's own
/// display string — storing the string would let the next stale echo through (#558).
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

    /// True when an unfocused write would replace a stored number (#558).
    /// A focused field always accepts the write. A stored `String` always accepts the write.
    /// The same display string is ignored too: storing it would turn the number into a `String`.
    static func shouldIgnoreNumericBindingSet(
        newValue _: String,
        storedValue: Any?,
        fieldIsFocused: Bool
    ) -> Bool {
        if fieldIsFocused { return false }
        return isStoredNumber(storedValue)
    }

    private static func isStoredNumber(_ value: Any?) -> Bool {
        switch value {
        case let double as Double:
            return double.isFinite
        case is Int:
            return true
        case let number as NSNumber:
            return number.doubleValue.isFinite
        default:
            return false
        }
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
                guard !shouldIgnoreNumericTextEcho(newValue, formState: formState) else { return }
                formState.setValue(newValue, for: id)
            }
        )
    }

    /// Whether an unfocused numeric text write would replace a stored number (#558).
    func shouldIgnoreNumericTextEcho(_ newValue: String, formState: DynamicFormState) -> Bool {
        DynamicFormStoredNumericDisplay.shouldIgnoreNumericBindingSet(
            newValue: newValue,
            storedValue: formState.getValue(for: id),
            fieldIsFocused: formState.focusedFieldId == id
        )
    }
}
