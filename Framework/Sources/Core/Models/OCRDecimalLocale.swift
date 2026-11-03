import Foundation

/// Resolves which `Locale` OCR uses for decimal and grouping separators (#631).
///
/// Capture region (from EXIF GPS reverse-geocode, or an explicit code) is an optional
/// guide. Missing region must not block OCR — language alone is enough.
///
/// `en` + region `DE` yields `en_DE` (comma decimals). That helps a photo taken in
/// Germany even when Vision language is English. GPS is never required.
enum OCRDecimalLocale {

    /// Priority: `override`, then language+region, then language alone.
    static func resolve(
        override: Locale?,
        regionCode: String?,
        language: OCRLanguage
    ) -> Locale {
        if let override {
            return override
        }
        if let region = normalizedRegionCode(regionCode) {
            return Locale(identifier: "\(language.rawValue)_\(region)")
        }
        return Locale(identifier: language.rawValue)
    }

    static func resolve(context: OCRContext) -> Locale {
        resolve(
            override: context.decimalLocale,
            regionCode: context.captureRegionCode,
            language: context.language
        )
    }

    private static func normalizedRegionCode(_ regionCode: String?) -> String? {
        guard let regionCode else { return nil }
        let trimmed = regionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.uppercased()
    }
}
