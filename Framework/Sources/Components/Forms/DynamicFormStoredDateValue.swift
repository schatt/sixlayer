import Foundation

/// Parses and normalizes date/time values stored in `DynamicFormState.fieldValues` for
/// `CustomFieldView` date fields (`DynamicDateField`, `DynamicTimeField`, `DynamicDateTimeField`).
///
/// **Primary contract:** `Date` — preferred for hosts mapping to Core Data / model `Date` attributes.
///
/// **Interoperability:** Also accepts `TimeInterval`, ISO-8601 strings, and the same medium/short
/// localized strings written by `DatePickerField` / `TimePickerField` / `DateTimePickerField` in
/// `AdvancedFieldTypes.swift`. See `Framework/docs/AdvancedFieldTypesGuide.md` (date contracts) and GitHub #266.
public enum DynamicFormStoredDateValue {

    /// Returns a `Date` suitable for `DatePicker` binding, or `nil` if nothing is stored / parseable.
    public static func date(fromStoredValue value: Any?) -> Date? {
        guard let value else { return nil }

        if let date = value as? Date {
            return date
        }

        if let doubleValue = value as? Double {
            return Date(timeIntervalSince1970: doubleValue)
        }

        if let number = value as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }

        if let string = value as? String {
            return date(fromLocalizedOrISOString: string)
        }

        return nil
    }

    private static func date(fromLocalizedOrISOString string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        if let iso = parseISO8601(trimmed) {
            return iso
        }

        let posix = Locale(identifier: "en_US_POSIX")

        let medium = DateFormatter()
        medium.locale = posix
        medium.dateStyle = .medium
        medium.timeStyle = .none
        if let d = medium.date(from: trimmed) {
            return d
        }

        let shortTime = DateFormatter()
        shortTime.locale = posix
        shortTime.dateStyle = .none
        shortTime.timeStyle = .short
        if let d = shortTime.date(from: trimmed) {
            return d
        }

        let mediumShort = DateFormatter()
        mediumShort.locale = posix
        mediumShort.dateStyle = .medium
        mediumShort.timeStyle = .short
        return mediumShort.date(from: trimmed)
    }

    private static func parseISO8601(_ string: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: string) {
            return d
        }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}
