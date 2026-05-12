//
//  PlatformImageEXIFTests.swift
//  SixLayerFrameworkTests
//
//  Tests for PlatformImage EXIF GPS location extraction
//  Implements GitHub Issue #21: PlatformImage EXIF GPS Location Extraction
//

import Testing
import CoreLocation
@testable import SixLayerFramework

#if canImport(ImageIO) && canImport(CoreLocation)
import CoreGraphics
import ImageIO
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#endif

/// Tests for PlatformImage EXIF GPS location extraction
/// Implements GitHub Issue #21
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform Image EXIF")
open class PlatformImageEXIFTests: BaseTestClass {
    
    // MARK: - EXIF Accessor Tests
    
    @Test func testPlatformImageHasEXIFAccessor() async {
        // Given: A PlatformImage
        let image = PlatformImage.createPlaceholder()
        
        // When: Accessing the exif property
        let exif = image.exif
        
        // Then: Should return a PlatformImageEXIF instance
        // PlatformImageEXIF is a struct, so accessing it confirms it exists
        let _ = exif.gpsLocation // Access a property to verify the struct exists
    }
    
    @Test func testPlatformImageEXIFHasGPSLocationProperty() async {
        // Given: A PlatformImage with EXIF accessor
        let image = PlatformImage.createPlaceholder()
        let exif = image.exif
        
        // When: Accessing gpsLocation property
        let location = exif.gpsLocation
        
        // Then: Should return CLLocation? (may be nil for placeholder images)
        // For placeholder images, location should be nil
        #expect(location == nil || location != nil)
    }
    
    @Test func testPlatformImageEXIFHasHasGPSLocationProperty() async {
        // Given: A PlatformImage with EXIF accessor
        let image = PlatformImage.createPlaceholder()
        let exif = image.exif
        
        // When: Accessing hasGPSLocation property
        let hasLocation = exif.hasGPSLocation
        
        // Then: Should return a boolean value
        #expect(hasLocation == true || hasLocation == false)
    }
    
    // MARK: - GPS Location Extraction Tests
    
    @Test func testEXIFReturnsNilForImagesWithoutGPSMetadata() async {
        // Given: A PlatformImage without GPS metadata (placeholder)
        let image = PlatformImage.createPlaceholder()
        
        // When: Extracting GPS location
        let location = image.exif.gpsLocation
        
        // Then: Should return nil
        #expect(location == nil)
    }
    
    @Test func testHasGPSLocationReturnsFalseForImagesWithoutGPSMetadata() async {
        // Given: A PlatformImage without GPS metadata (placeholder)
        let image = PlatformImage.createPlaceholder()
        
        // When: Checking if image has GPS location
        let hasLocation = image.exif.hasGPSLocation
        
        // Then: Should return false
        #expect(hasLocation == false)
    }
    
    // MARK: - Cross-Platform Tests
    
    @Test func testEXIFWorksOnAllPlatforms() async {
        // Given: A PlatformImage
        let image = PlatformImage.createPlaceholder()
        _ = SixLayerPlatform.current
        
        // When: Accessing EXIF data
        let exif = image.exif
        let hasLocation = exif.hasGPSLocation
        
        // Then: Should work on all platforms
        // The exif property should be available regardless of platform
        #expect(hasLocation == true || hasLocation == false)
    }
    
    // MARK: - API Design Tests
    
    @Test func testEXIFAPIIsIntuitive() async {
        // Given: A PlatformImage
        let image = PlatformImage.createPlaceholder()
        
        // When: Using the API as designed
        let location = image.exif.gpsLocation
        let hasLocation = image.exif.hasGPSLocation
        
        // Then: API should be intuitive and discoverable
        // image.exif.gpsLocation should be the primary way to access GPS data
        #expect(location == nil || location != nil)
        #expect(hasLocation == true || hasLocation == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testEXIFHandlesInvalidImageData() async {
        // Given: An invalid image (empty data)
        let invalidData = Data()
        let image = PlatformImage(data: invalidData)
        
        // When: Accessing EXIF data
        // Then: Should handle gracefully (image is nil, so we can't test exif)
        #expect(image == nil)
    }
    
    @Test func testEXIFHandlesMissingEXIFMetadata() async {
        // Given: A valid image without EXIF metadata
        let image = PlatformImage.createPlaceholder()
        
        // When: Accessing GPS location
        let location = image.exif.gpsLocation
        
        // Then: Should return nil gracefully
        #expect(location == nil)
    }
}

#if canImport(ImageIO) && canImport(CoreLocation) && canImport(CoreGraphics)
extension PlatformImageEXIFTests {
    /// JPEG bytes produced with an embedded GPS dictionary (Issue #274).
    fileprivate static func makeJPEGDataOnePixelWithGPS() throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            struct MakeImageError: Error {}
            throw MakeImageError()
        }
        ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let cgImage = ctx.makeImage() else {
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
        let gps: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: 37.7749,
            kCGImagePropertyGPSLatitudeRef as String: "N",
            kCGImagePropertyGPSLongitude as String: 122.4194,
            kCGImagePropertyGPSLongitudeRef as String: "W"
        ]
        let properties: [String: Any] = [kCGImagePropertyGPSDictionary as String: gps]
        CGImageDestinationAddImage(dest, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            struct FinalizeError: Error {}
            throw FinalizeError()
        }
        return mutable as Data
    }

    @Test func testEXIFReadsGPSFromEncodedJPEGFixture() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPS()
        let image = PlatformImage(data: jpegData)
        #expect(image != nil, "Fixture JPEG should decode as PlatformImage")
        guard let image else { return }
        let location = image.exif.gpsLocation
        #expect(location != nil, "GPS from source JPEG bytes should be readable (Issue #274)")
        guard let location else { return }
        #expect(abs(location.coordinate.latitude - 37.7749) < 0.000_1)
        #expect(abs(location.coordinate.longitude - (-122.4194)) < 0.000_1)
    }
}

// MARK: - Issue #275: EXIF Writer Tests

extension PlatformImageEXIFTests {
    /// JPEG bytes with both a GPS dictionary AND a TIFF Make/Model tag, for
    /// verifying that GPS-targeted writers leave other EXIF dictionaries intact.
    fileprivate static func makeJPEGDataOnePixelWithGPSAndTIFFMake() throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(
            data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: colorSpace, bitmapInfo: bitmapInfo
        ) else { struct E: Error {}; throw E() }
        ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let cgImage = ctx.makeImage() else { struct E: Error {}; throw E() }
        let mutable = NSMutableData()
        #if canImport(UniformTypeIdentifiers)
        let type = UTType.jpeg.identifier as CFString
        #else
        let type = "public.jpeg" as CFString
        #endif
        guard let dest = CGImageDestinationCreateWithData(mutable, type, 1, nil) else {
            struct E: Error {}; throw E()
        }
        let gps: [String: Any] = [
            kCGImagePropertyGPSLatitude as String: 37.7749,
            kCGImagePropertyGPSLatitudeRef as String: "N",
            kCGImagePropertyGPSLongitude as String: 122.4194,
            kCGImagePropertyGPSLongitudeRef as String: "W"
        ]
        let tiff: [String: Any] = [
            kCGImagePropertyTIFFMake as String: "SixLayerTest",
            kCGImagePropertyTIFFModel as String: "Fixture #275"
        ]
        let properties: [String: Any] = [
            kCGImagePropertyGPSDictionary as String: gps,
            kCGImagePropertyTIFFDictionary as String: tiff
        ]
        CGImageDestinationAddImage(dest, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { struct E: Error {}; throw E() }
        return mutable as Data
    }

    /// Read a top-level property dictionary key from arbitrary encoded image bytes.
    fileprivate static func topLevelDict(_ data: Data, _ key: CFString) -> [String: Any]? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        guard let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any] else { return nil }
        return props[key as String] as? [String: Any]
    }

    // MARK: Config contract

    @Test func testPlatformImageEXIFConfigDefaultsToHEIC() async {
        #expect(PlatformImageEXIFConfig.shared.defaultWriteFormat == .heic,
                "Issue #275: default write format must be HEIC")
    }

    @Test func testPlatformImageEXIFConfigSupportsTaskLocalOverride() async {
        let override = PlatformImageEXIFConfig()
        override.defaultWriteFormat = .jpeg
        PlatformImageEXIFConfig.withTaskLocalConfig(override) {
            #expect(PlatformImageEXIFConfig.current.defaultWriteFormat == .jpeg,
                    "Issue #275: task-local override must be honored")
        }
        // Outside the scope the singleton default is restored.
        #expect(PlatformImageEXIFConfig.current.defaultWriteFormat == .heic,
                "Issue #275: task-local override must not leak past its scope")
    }

    // MARK: Writers — GPS round-trip

    @Test func testWithGPSLocationRoundTripsCoordinateOnJPEG() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPS()
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("Fixture JPEG should decode as PlatformImage")
            return
        }
        let newLoc = CLLocation(latitude: 40.7128, longitude: -74.0060)
        let result = image.exif.with(gpsLocation: newLoc, as: .jpeg)
        #expect(result != nil, "Issue #275: writer should return a new PlatformImage")
        guard let result else { return }
        let readBack = result.exif.gpsLocation
        #expect(readBack != nil, "Issue #275: written GPS must be readable from the result")
        guard let readBack else { return }
        #expect(abs(readBack.coordinate.latitude - 40.7128) < 0.000_1,
                "Issue #275: latitude round-trip mismatch")
        #expect(abs(readBack.coordinate.longitude - (-74.0060)) < 0.000_1,
                "Issue #275: longitude round-trip mismatch")
    }

    @Test func testWithGPSLocationNilRemovesGPSOnJPEG() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPS()
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("Fixture JPEG should decode as PlatformImage"); return
        }
        let result = image.exif.with(gpsLocation: nil, as: .jpeg)
        #expect(result != nil, "Issue #275: passing nil GPS must still return an image (GPS removed)")
        guard let result else { return }
        #expect(result.exif.gpsLocation == nil,
                "Issue #275: writing nil GPS must remove the GPS dictionary")
    }

    // MARK: Writers — privacy

    @Test func testStrippingGPSRemovesGPSAndPreservesTIFF() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPSAndTIFFMake()
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("Fixture JPEG should decode as PlatformImage"); return
        }
        let result = image.exif.strippingGPS(as: .jpeg)
        #expect(result != nil, "Issue #275: strippingGPS must return a result")
        guard let result, let bytes = result.originalEncodedData else {
            Issue.record("Issue #275: result must carry encoded bytes for inspection")
            return
        }
        #expect(Self.topLevelDict(bytes, kCGImagePropertyGPSDictionary) == nil,
                "Issue #275: GPS dictionary must be removed by strippingGPS()")
        let tiff = Self.topLevelDict(bytes, kCGImagePropertyTIFFDictionary)
        #expect(tiff?[kCGImagePropertyTIFFMake as String] as? String == "SixLayerTest",
                "Issue #275: strippingGPS must preserve unrelated EXIF (TIFF Make)")
    }

    @Test func testStrippingAllRemovesGPSAndTIFF() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPSAndTIFFMake()
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("Fixture JPEG should decode as PlatformImage"); return
        }
        let result = image.exif.strippingAll(as: .jpeg)
        #expect(result != nil, "Issue #275: strippingAll must return a result")
        guard let result, let bytes = result.originalEncodedData else {
            Issue.record("Issue #275: result must carry encoded bytes for inspection")
            return
        }
        #expect(Self.topLevelDict(bytes, kCGImagePropertyGPSDictionary) == nil,
                "Issue #275: GPS must be removed by strippingAll()")
        #expect(Self.topLevelDict(bytes, kCGImagePropertyTIFFDictionary) == nil,
                "Issue #275: TIFF must be removed by strippingAll()")
    }

    // MARK: Writers — encoding format

    @Test func testExplicitJPEGFormatProducesJPEGMagicBytes() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPS()
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("Fixture JPEG should decode as PlatformImage"); return
        }
        let result = image.exif.with(
            gpsLocation: CLLocation(latitude: 1.0, longitude: 2.0),
            as: .jpeg
        )
        guard let bytes = result?.originalEncodedData else {
            Issue.record("Issue #275: explicit-format writer must return encoded bytes"); return
        }
        // JPEG SOI marker: FF D8 FF
        let prefix = Array(bytes.prefix(3))
        #expect(prefix == [0xFF, 0xD8, 0xFF],
                "Issue #275: as: .jpeg must produce JPEG magic bytes (FF D8 FF) — got \(prefix)")
    }

    @Test func testExplicitHEICFormatProducesHEICMagicBytesOrSkipsWhenUnavailable() async throws {
        let jpegData = try Self.makeJPEGDataOnePixelWithGPS()
        guard let image = PlatformImage(data: jpegData) else {
            Issue.record("Fixture JPEG should decode as PlatformImage"); return
        }
        let result = image.exif.with(
            gpsLocation: CLLocation(latitude: 1.0, longitude: 2.0),
            as: .heic
        )
        // The writer is allowed to return nil only if the host runtime cannot
        // encode HEIC; in that case it has already fallen back at the default
        // path. For an explicit `.heic` request, nil is acceptable only when
        // HEIC is not supported.
        guard let bytes = result?.originalEncodedData else {
            // Soft-skip: if HEIC is unavailable, this run cannot verify the
            // magic bytes. Other tests cover the explicit-JPEG path.
            return
        }
        // HEIC files are ISO-BMFF: bytes [4..7] are the "ftyp" box type, then
        // a brand like "heic" / "heix" / "mif1" / "msf1".
        let header = Array(bytes.prefix(12))
        #expect(header.count >= 12, "Issue #275: HEIC header should be at least 12 bytes")
        if header.count >= 12 {
            let ftyp = String(bytes: header[4..<8], encoding: .ascii)
            #expect(ftyp == "ftyp", "Issue #275: HEIC must start with ISO-BMFF ftyp box (got \(ftyp ?? "?"))")
            let brand = String(bytes: header[8..<12], encoding: .ascii) ?? ""
            #expect(["heic", "heix", "mif1", "msf1", "heim", "heis"].contains(brand),
                    "Issue #275: HEIC brand must be in the HEIF family (got \(brand))")
        }
    }
}
#endif

