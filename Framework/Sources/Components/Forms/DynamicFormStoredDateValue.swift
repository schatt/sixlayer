import Foundation

/// Parses and normalizes date/time values stored in `DynamicFormState.fieldValues` for
/// `CustomFieldView` date fields (`DynamicDateField`, `DynamicTimeField`, `DynamicDateTimeField`).
///
/// **Primary contract:** `Date` — preferred for hosts mapping to Core Data / model `Date` attributes.
///
/// **Interoperability:** Also accepts `TimeInterval`, ISO-8601 strings, `en_US_POSIX` medium/short
/// strings, and those same styles in `Locale.current` as written by `DatePickerField` /
/// `TimePickerField` / `DateTimePickerField`. POSIX is tried first (#615, #621).
/// See `Framework/docs/AdvancedFieldTypesGuide.md` (date contracts) and GitHub #266.
public enum DynamicFormStoredDateValue {

    /// Returns a `Date` suitable for `DatePicker` binding, or `nil` if nothing is stored / parseable.
    /// Medium and short strings use `Locale.current` when POSIX does not parse them (#621).
    public static func date(fromStoredValue value: Any?) -> Date? {
        date(fromStoredValue: value, locale: .current)
    }

    /// `locale` is the locale `DatePickerField` used. POSIX medium and short strings are tried first.
    static func date(fromStoredValue value: Any?, locale: Locale) -> Date? {
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
            return date(fromLocalizedOrISOString: string, locale: locale)
        }

        return nil
    }

    private static func date(fromLocalizedOrISOString string: String, locale: Locale) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        if let iso = parseISO8601(trimmed) {
            return iso
        }

        return styledDate(from: trimmed, locale: locale)
    }

    /// Same styles `DatePickerField`, `TimePickerField`, and `DateTimePickerField` write.
    private static func styledDate(from text: String, locale: Locale) -> Date? {
        if let date = formatter(locale: locale, dateStyle: .medium, timeStyle: .none).date(from: text) {
            return date
        }
        if let date = formatter(locale: locale, dateStyle: .none, timeStyle: .short).date(from: text) {
            return date
        }
        return formatter(locale: locale, dateStyle: .medium, timeStyle: .short).date(from: text)
    }

    private static func formatter(
        locale: Locale,
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
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
