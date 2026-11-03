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
}
