import Foundation

/// Resolves which `Locale` OCR uses for decimal and grouping separators (#631).
///
/// Capture region (from EXIF GPS reverse-geocode, or an explicit code) is an optional
/// guide. Missing region must not block OCR — language alone is enough.
enum OCRDecimalLocale {

    /// Priority: `override`, then language+region, then language alone.
    /// Stub: region and override are ignored so the region tests fail for the right reason.
    static func resolve(
        override: Locale?,
        regionCode: String?,
        language: OCRLanguage
    ) -> Locale {
        _ = override
        _ = regionCode
        return Locale(identifier: language.rawValue)
    }

    static func resolve(context: OCRContext) -> Locale {
        resolve(
            override: context.decimalLocale,
            regionCode: context.captureRegionCode,
            language: context.language
        )
    }
}
