import Foundation

/// Parses a decimal string stored by a form field (#624).
///
/// `Double(_:)` accepts only a POSIX decimal. A decimal pad in a comma locale stores `4,5`.
/// POSIX is tried first, so `4.5` stays 4.5 when the locale uses a comma. A string that is
/// not entirely one number (`4,5abc`, `..`) is not a value. Same scan Core Data assignment uses (#621).
enum DynamicFormStoredDecimal {

    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// Finite `Double` for the whole string, or nil when it is not one number in `locale`.
    static func double(fromStoredText text: String, locale: Locale = .current) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let double = Double(trimmed), double.isFinite {
            return double
        }
        guard let decimal = decimal(fromEntire: trimmed, locale: locale) else { return nil }
        let double = NSDecimalNumber(decimal: decimal).doubleValue
        guard double.isFinite else { return nil }
        return double
    }

    /// The whole string is one decimal. POSIX is tried first.
    static func decimal(fromEntire text: String, locale: Locale) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let posix = scanDecimal(trimmed, locale: posixLocale) {
            return posix
        }
        if locale.identifier == posixLocale.identifier { return nil }
        return scanDecimal(trimmed, locale: locale)
    }

    private static func scanDecimal(_ text: String, locale: Locale) -> Decimal? {
        let scanner = Scanner(string: text)
        scanner.locale = locale
        guard let decimal = scanner.scanDecimal(), scanner.isAtEnd else { return nil }
        return decimal
    }
}
