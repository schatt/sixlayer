import CoreLocation
import Foundation

/// Maps a capture location to an ISO region code for OCR decimal guidance (#631).
protocol OCRCaptureRegionResolving: Sendable {
    func regionCode(for location: CLLocation) async -> String?
}

/// Test double: always returns a fixed region (or `nil`).
struct FixedOCRCaptureRegionResolver: OCRCaptureRegionResolving {
    let regionCode: String?

    func regionCode(for location: CLLocation) async -> String? {
        regionCode
    }
}

/// Default resolver: reverse-geocode via `CLGeocoder` (optional; failures yield `nil`).
struct CLGeocoderOCRCaptureRegionResolver: OCRCaptureRegionResolving {
    func regionCode(for location: CLLocation) async -> String? {
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            return placemarks.first?.isoCountryCode
        } catch {
            return nil
        }
    }
}

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

    /// Optionally enrich `context` with a capture region from GPS.
    ///
    /// GPS is a guide only: missing location / failed resolve leaves context unchanged.
    /// Explicit `captureRegionCode` or `decimalLocale` wins — GPS does not override.
    static func contextByApplyingCaptureGPS(
        _ context: OCRContext,
        location: CLLocation?,
        resolver: OCRCaptureRegionResolving = CLGeocoderOCRCaptureRegionResolver()
    ) async -> OCRContext {
        if context.decimalLocale != nil { return context }
        if normalizedRegionCode(context.captureRegionCode) != nil { return context }
        guard let location else { return context }
        guard let region = await resolver.regionCode(for: location),
              let normalized = normalizedRegionCode(region) else {
            return context
        }
        return context.with(captureRegionCode: normalized)
    }

    private static func normalizedRegionCode(_ regionCode: String?) -> String? {
        guard let regionCode else { return nil }
        let trimmed = regionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.uppercased()
    }
}
