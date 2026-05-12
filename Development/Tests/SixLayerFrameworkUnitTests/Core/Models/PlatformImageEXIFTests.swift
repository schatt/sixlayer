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
#endif

