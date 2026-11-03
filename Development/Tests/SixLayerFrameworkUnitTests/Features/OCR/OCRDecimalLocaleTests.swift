import CoreGraphics
import CoreLocation
import Foundation
import ImageIO
import Testing
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

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

    @Test func serviceEnrichesContextFromImageEXIFGPS() async throws {
        let jpegData = try makeJPEGDataOnePixelWithGPS(
            latitude: 52.52,
            longitude: 13.405
        )
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("GPS JPEG fixture should decode")
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

    @Test func serviceSkipsGPSWhenContextAlreadyHasRegion() async throws {
        let jpegData = try makeJPEGDataOnePixelWithGPS(
            latitude: 52.52,
            longitude: 13.405
        )
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("GPS JPEG fixture should decode")
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

    private func makeJPEGDataOnePixelWithGPS(
        latitude: Double,
        longitude: Double
    ) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
            | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ), let cgImage = {
            ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            return ctx.makeImage()
        }() else {
            struct MakeImageError: Error {}
            throw MakeImageError()
        }
        let mutable = NSMutableData()
        #if canImport(UniformTypeIdentifiers)
        let type = UTType.jpeg.identifier as CFString
        #else
        let type = "public.jpeg" as CFString
        #endif
        guard let dest = CGImageDestinationCreateWithData(mutable, type, 1, nil) else {
            struct DestinationError: Error {}
            throw DestinationError()
        }
        let latRef = latitude >= 0 ? "N" : "S"
        let lonRef = longitude >= 0 ? "E" : "W"
        let gps: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: abs(latitude),
            kCGImagePropertyGPSLatitudeRef as String: latRef,
            kCGImagePropertyGPSLongitude as String: abs(longitude),
            kCGImagePropertyGPSLongitudeRef as String: lonRef
        ]
        CGImageDestinationAddImage(
            dest,
            cgImage,
            [kCGImagePropertyGPSDictionary as String: gps] as CFDictionary
        )
        guard CGImageDestinationFinalize(dest) else {
            struct FinalizeError: Error {}
            throw FinalizeError()
        }
        return mutable as Data
    }
}
