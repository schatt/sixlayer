import Foundation
import SwiftUI

/// Formats values stored in ``DynamicFormState`` for numeric text fields (`DynamicNumberField`, `DynamicIntegerField`).
///
/// **Read contract:** `String` is shown as-is; `Int`, `Double`, and `NSNumber` are formatted for display without
/// scientific notation for typical magnitudes. **Write contract:** fields continue to store `String` from the text binding.
public enum DynamicFormStoredNumericDisplay {

    /// Display string for a stored field value, falling back to `defaultValue` then `""`.
    public static func displayString(fromStoredValue value: Any?, defaultValue: String? = nil) -> String {
        (value as? String) ?? defaultValue ?? ""
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
