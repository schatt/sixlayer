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
}

@MainActor
extension DynamicFormField {
    /// Text binding that reads numeric stored values as display strings and writes `String`.
    func numericTextBinding(formState: DynamicFormState) -> Binding<String> {
        Binding(
            get: {
                DynamicFormStoredNumericDisplay.displayString(
                    fromStoredValue: formState.getValue(for: id),
                    defaultValue: defaultValue
                )
            },
            set: { formState.setValue($0, for: id) }
        )
    }
}
