import CoreLocation
import Foundation
import Testing

@testable import SixLayerFramework

/// OCR decimal locale: override, optional capture region, then language (#631).
/// GPS is only a guide — missing region must not block resolution.
@Suite("OCR decimal locale")
struct OCRDecimalLocaleTests {

    @Test func overrideWinsOverRegionAndLanguage() {
        let override = Locale(identifier: "fr_FR")
        let resolved = OCRDecimalLocale.resolve(
            override: override,
            regionCode: "US",
            language: .german
        )
        #expect(resolved.identifier == override.identifier)
    }

    @Test func regionWithLanguageUsesPlaceDecimalRules() {
        let inGermany = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: "DE",
            language: .english
        )
        #expect(inGermany.decimalSeparator == ",")
        #expect(inGermany.groupingSeparator == ".")

        let inUS = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: "US",
            language: .german
        )
        #expect(inUS.decimalSeparator == ".")
        #expect(inUS.groupingSeparator == ",")
    }

    @Test func missingRegionFallsBackToLanguage() {
        let english = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: nil,
            language: .english
        )
        #expect(english.decimalSeparator == ".")

        let german = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: nil,
            language: .german
        )
        #expect(german.decimalSeparator == ",")
    }

    @Test func emptyOrBlankRegionFallsBackToLanguage() {
        let resolved = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: "  ",
            language: .english
        )
        #expect(resolved.decimalSeparator == ".")
    }

    @Test func regionCodeIsNormalizedToUppercase() {
        let resolved = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: "de",
            language: .english
        )
        #expect(resolved.decimalSeparator == ",")
    }

    @Test func contextUsesCaptureRegionWhenPresent() {
        let context = OCRContext(
            language: .english,
            captureRegionCode: "DE"
        )
        let locale = OCRDecimalLocale.resolve(context: context)
        #expect(locale.decimalSeparator == ",")
    }

    @Test func contextOverrideBeatsCaptureRegion() {
        let context = OCRContext(
            language: .english,
            decimalLocale: Locale(identifier: "en_US"),
            captureRegionCode: "DE"
        )
        let locale = OCRDecimalLocale.resolve(context: context)
        #expect(locale.decimalSeparator == ".")
    }

    @Test func englishFourCommaFiveFailsClosedWithoutRegion() {
        let locale = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: nil,
            language: .english
        )
        let service = OCRService()
        let group = CalculationGroup(
            id: "cost",
            formula: "cost = gallons * price",
            dependentFields: ["gallons", "price"],
            priority: 1
        )
        #expect(
            service.evaluateCalculationGroup(
                group,
                fieldValues: ["gallons": "4,5", "price": "2"],
                locale: locale
            ) == nil
        )
    }

    @Test func englishLanguageWithGermanRegionParsesCommaDecimal() {
        let locale = OCRDecimalLocale.resolve(
            override: nil,
            regionCode: "DE",
            language: .english
        )
        let service = OCRService()
        let group = CalculationGroup(
            id: "cost",
            formula: "cost = gallons * price",
            dependentFields: ["gallons", "price"],
            priority: 1
        )
        #expect(
            service.evaluateCalculationGroup(
                group,
                fieldValues: ["gallons": "4,5", "price": "2"],
                locale: locale
            ) == 9
        )
    }

    @Test func gpsRegionGuidesWhenContextHasNoRegion() async {
        let berlin = CLLocation(latitude: 52.52, longitude: 13.405)
        let context = OCRContext(language: .english)
        let enriched = await OCRDecimalLocale.contextByApplyingCaptureGPS(
            context,
            location: berlin,
            resolver: FixedOCRCaptureRegionResolver(regionCode: "DE")
        )
        #expect(enriched.captureRegionCode == "DE")
        #expect(OCRDecimalLocale.resolve(context: enriched).decimalSeparator == ",")
    }

    @Test func gpsDoesNotOverrideExplicitRegionOrLocale() async {
        let berlin = CLLocation(latitude: 52.52, longitude: 13.405)
        let withRegion = await OCRDecimalLocale.contextByApplyingCaptureGPS(
            OCRContext(language: .english, captureRegionCode: "US"),
            location: berlin,
            resolver: FixedOCRCaptureRegionResolver(regionCode: "DE")
        )
        #expect(withRegion.captureRegionCode == "US")

        let withOverride = await OCRDecimalLocale.contextByApplyingCaptureGPS(
            OCRContext(language: .english, decimalLocale: Locale(identifier: "en_US")),
            location: berlin,
            resolver: FixedOCRCaptureRegionResolver(regionCode: "DE")
        )
        #expect(withOverride.captureRegionCode == nil)
        #expect(OCRDecimalLocale.resolve(context: withOverride).decimalSeparator == ".")
    }

    @Test func missingGPSLeavesContextUnchanged() async {
        let enriched = await OCRDecimalLocale.contextByApplyingCaptureGPS(
            OCRContext(language: .english),
            location: nil,
            resolver: FixedOCRCaptureRegionResolver(regionCode: "DE")
        )
        #expect(enriched.captureRegionCode == nil)
        #expect(OCRDecimalLocale.resolve(context: enriched).decimalSeparator == ".")
    }

    @Test func serviceEnrichmentLeavesContextWithoutImageGPS() async {
        let service = OCRService()
        service.captureRegionResolver = FixedOCRCaptureRegionResolver(regionCode: "DE")
        let enriched = await service.contextEnrichedFromCaptureGPS(
            OCRContext(language: .english),
            image: PlatformImage()
        )
        #expect(enriched.captureRegionCode == nil)
    }

    @Test func serviceEnrichesContextFromImageEXIFGPS() async {
        guard let image = Self.platformImageWithBerlinGPS() else {
            Issue.record("Berlin GPS JPEG fixture should decode")
            return
        }
        #expect(image.exif.gpsLocation != nil)

        let service = OCRService()
        service.captureRegionResolver = FixedOCRCaptureRegionResolver(regionCode: "DE")
        let enriched = await service.contextEnrichedFromCaptureGPS(
            OCRContext(language: .english),
            image: image
        )
        #expect(enriched.captureRegionCode == "DE")
        #expect(OCRDecimalLocale.resolve(context: enriched).decimalSeparator == ",")
    }

    @Test func serviceSkipsGPSWhenContextAlreadyHasRegion() async {
        guard let image = Self.platformImageWithBerlinGPS() else {
            Issue.record("Berlin GPS JPEG fixture should decode")
            return
        }

        let service = OCRService()
        service.captureRegionResolver = FixedOCRCaptureRegionResolver(regionCode: "DE")
        let enriched = await service.contextEnrichedFromCaptureGPS(
            OCRContext(language: .english, captureRegionCode: "US"),
            image: image
        )
        #expect(enriched.captureRegionCode == "US")
    }

    /// Same bytes as `Development/TestImages/one-pixel-berlin-gps.jpg` (embedded so XCTest need not resolve source paths).
    private static func platformImageWithBerlinGPS() -> PlatformImage? {
        let base64 = "/9j/4AAQSkZJRgABAQAASABIAAD/4QCyRXhpZgAATU0AKgAAAAgAAodpAAQAAAABAAAAJoglAAQAAAABAAAARAAAAAAAAqACAAQAAAABAAAAAaADAAQAAAABAAAAAQAAAAAABAABAAIAAAACTgAAAAACAAUAAAADAAAAegADAAIAAAACRQAAAAAEAAUAAAADAAAAkgAAAAAAAAA0AAAAAQAAAB8AAAABAAAEsAAAAGQAAAANAAAAAQAAABgAAAABAAAHCAAAAGT/7QA4UGhvdG9zaG9wIDMuMAA4QklNBAQAAAAAAAA4QklNBCUAAAAAABDUHYzZjwCyBOmACZjs+EJ+/8AAEQgAAQABAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAgICAgICAwICAwUDAwMFBgUFBQUGCAYGBgYGCAoICAgICAgKCgoKCgoKCgwMDAwMDA4ODg4ODw8PDw8PDw8PD//bAEMBAgICBAQEBwQEBxALCQsQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEP/dAAQAAf/aAAwDAQACEQMRAD8A/fyiiigD/9k="
        guard let data = Data(base64Encoded: base64) else { return nil }
        return PlatformImage(data: data)
    }
}
