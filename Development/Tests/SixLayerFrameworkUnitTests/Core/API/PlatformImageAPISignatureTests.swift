import Testing

//
//  PlatformImageAPISignatureTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates ALL public API signatures for PlatformImage to prevent breaking changes.
//  These tests would have caught the PlatformImage initializer breaking change.
//
//  TESTING SCOPE:
//  - All public initializer signatures and parameter labels
//  - API compatibility and backward compatibility
//  - Parameter label requirements and optional parameters
//  - Cross-platform API consistency
//  - Breaking change detection for public interface
//
//  METHODOLOGY:
//  - Test every public initializer signature exists
//  - Test parameter labels are correct and required
//  - Test backward compatibility with old API patterns
//  - Test cross-platform API consistency
//  - Test that API changes would break these tests
//
//  CRITICAL: These tests MUST fail if any public API signature changes
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import SixLayerFramework


/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformImageAPISignatureTests: BaseTestClass {
    
    // MARK: - API Signature Tests
    
    /// BUSINESS PURPOSE: Verify all public initializer signatures exist and work
    /// TESTING SCOPE: Tests that ALL public PlatformImage initializers exist and function
    /// METHODOLOGY: Test each initializer signature directly
    @Test func testPlatformImageInitializerSignatures() {
        // Test 1: Default initializer
        #expect(PlatformImage().isEmpty, "Default PlatformImage is empty")
        
        // Test 2: Data initializer is failable; truncated JPEG follows the platform decoder.
        expectTruncatedJPEGHeaderMatchesPlatformDecoder()
        
        // Test 3: Platform-specific initializers
        #if os(iOS)
        let uiImage = PlatformImage.createPlaceholder().uiImage // 6LAYER_ALLOW: testing PlatformImage boundary API access
        let uiImageInit = PlatformImage(uiImage: uiImage) // 6LAYER_ALLOW: testing PlatformImage construction from platform-specific image
        // uiImageInit is non-optional, so no nil check needed
        #expect(uiImageInit.uiImage == uiImage, "UIImage initializer should work correctly") // 6LAYER_ALLOW: testing PlatformImage boundary property access
        
        // Test 4: Backward compatibility initializer (implicit parameter)
        let implicitInit = PlatformImage(uiImage) // 6LAYER_ALLOW: testing PlatformImage construction from platform-specific image
        // implicitInit is non-optional, so no nil check needed
        #expect(implicitInit.uiImage == uiImage, "Implicit parameter initializer should work correctly") // 6LAYER_ALLOW: testing PlatformImage boundary property access
        #elseif os(macOS)
        let nsImage = PlatformImage.createPlaceholder().nsImage // 6LAYER_ALLOW: testing PlatformImage boundary API access
        let nsImageInit = PlatformImage(nsImage: nsImage) // 6LAYER_ALLOW: testing PlatformImage construction from platform-specific image
        // nsImageInit is non-optional, so no nil check needed
        #expect(nsImageInit.nsImage == nsImage, "NSImage initializer should work correctly") // 6LAYER_ALLOW: testing PlatformImage boundary property access

        // Test 4: Backward compatibility initializer (implicit parameter)
        let implicitInit = PlatformImage(nsImage) // 6LAYER_ALLOW: testing PlatformImage construction from platform-specific image
        // implicitInit is non-optional, so no nil check needed
        #expect(implicitInit.nsImage == nsImage, "Implicit parameter initializer should work correctly") // 6LAYER_ALLOW: testing PlatformImage boundary property access
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify parameter labels are correct and required
    /// TESTING SCOPE: Tests that parameter labels match expected API
    /// METHODOLOGY: Test parameter label requirements
    @Test func testPlatformImageParameterLabels() {
        #if os(iOS)
        let uiImage = PlatformImage.createPlaceholder().uiImage
        
        // Test explicit parameter label (current API)
        let explicitInit = PlatformImage(uiImage: uiImage)
        
        // Test implicit parameter (backward compatibility)
        let implicitInit = PlatformImage(uiImage)
        
        // Verify both produce equivalent results
        #expect(explicitInit.uiImage == implicitInit.uiImage, "Both initializers should produce equivalent results")
        #elseif os(macOS)
        let nsImage = PlatformImage.createPlaceholder().nsImage
        
        // Test explicit parameter label (current API)
        let explicitInit = PlatformImage(nsImage: nsImage)
        
        // Test implicit parameter (backward compatibility)
        let implicitInit = PlatformImage(nsImage)
        
        // Verify both produce equivalent results
        #expect(explicitInit.nsImage == implicitInit.nsImage, "Both initializers should produce equivalent results")
    #endif
    }
    
    /// BUSINESS PURPOSE: Verify backward compatibility with old API patterns
    /// TESTING SCOPE: Tests that old API usage patterns still work
    /// METHODOLOGY: Test the exact API patterns used in Layer 4 callbacks
    @Test func testPlatformImageBackwardCompatibility() {
        #if os(iOS)
        let uiImage = PlatformImage.createPlaceholder().uiImage
        
        // Test the EXACT pattern used in Layer 4 callbacks
        // This is the pattern that was broken in 4.6.2
        let callbackPattern = PlatformImage(uiImage)
        #expect(callbackPattern.uiImage == uiImage, "Callback pattern should produce correct result")
        
        // Test that both old and new patterns work
        let newPattern = PlatformImage(uiImage: uiImage)
        #expect(newPattern.uiImage == callbackPattern.uiImage, "Old and new patterns should be equivalent")
        #elseif os(macOS)
        let nsImage = PlatformImage.createPlaceholder().nsImage
        
        // Test the EXACT pattern used in Layer 4 callbacks
        let callbackPattern = PlatformImage(nsImage)
        #expect(callbackPattern.nsImage == nsImage, "Callback pattern should produce correct result")
        
        // Test that both old and new patterns work
        let newPattern = PlatformImage(nsImage: nsImage)
        #expect(newPattern.nsImage == callbackPattern.nsImage, "Old and new patterns should be equivalent")
    #endif
    }
    
    /// BUSINESS PURPOSE: Verify cross-platform API consistency
    /// TESTING SCOPE: Tests that API is consistent across platforms
    /// METHODOLOGY: Test API patterns work on all platforms
    @Test func testPlatformImageCrossPlatformConsistency() {
        // Data initializer exists on all platforms; truncated JPEG is decoder-specific.
        expectTruncatedJPEGHeaderMatchesPlatformDecoder()
        
        #expect(PlatformImage().isEmpty, "Default PlatformImage is empty")
        
        // Test that both implicit and explicit patterns work
        #if os(iOS)
        let uiImage = PlatformImage.createPlaceholder().uiImage
        let implicit = PlatformImage(uiImage)
        let explicit = PlatformImage(uiImage: uiImage)
        #expect(implicit.uiImage == explicit.uiImage, "iOS patterns should be equivalent")
        #elseif os(macOS)
        let nsImage = PlatformImage.createPlaceholder().nsImage
        let implicit = PlatformImage(nsImage)
        let explicit = PlatformImage(nsImage: nsImage)
        #expect(implicit.nsImage == explicit.nsImage, "macOS patterns should be equivalent")
    #endif
    }
    
    /// BUSINESS PURPOSE: Verify API breaking change detection
    /// TESTING SCOPE: Tests that would fail if API signatures change
    /// METHODOLOGY: Test specific API patterns that must remain stable
    @Test func testPlatformImageBreakingChangeDetection() {
        // This test would have FAILED in version 4.6.2 before our fix
        // It tests the exact API pattern that was broken
        
        #if os(iOS)
        let uiImage = PlatformImage.createPlaceholder().uiImage
        
        // Test the broken pattern from Layer 4 callbacks
        // This should work with our backward compatibility fix
        let brokenPattern = PlatformImage(uiImage)
        #expect(brokenPattern.uiImage == uiImage, "Broken pattern should produce correct result")
        #expect(brokenPattern.size == uiImage.size, "Broken pattern should preserve image properties")
        #elseif os(macOS)
        let nsImage = PlatformImage.createPlaceholder().nsImage
        
        // Test the broken pattern from Layer 4 callbacks
        let brokenPattern = PlatformImage(nsImage)
        #expect(brokenPattern.nsImage == nsImage, "Broken pattern should produce correct result")
        #expect(brokenPattern.size == nsImage.size, "Broken pattern should preserve image properties")
    #endif
    }
    
    // MARK: - CGImage Initializer Tests (Issue #23)
    
    /// BUSINESS PURPOSE: Verify CGImage initializer exists and works (Issue #23)
    /// TESTING SCOPE: Tests that PlatformImage can be initialized from CGImage
    /// METHODOLOGY: Test CGImage initializer on both platforms
    @Test func testPlatformImageCGImageInitializer() {
        // Given: A CGImage
        // Create a simple test CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let cgImage = context.makeImage()!
        
        // When: Creating PlatformImage from CGImage
        #if os(iOS)
        let platformImage = PlatformImage(cgImage: cgImage)
        #expect(platformImage.size.width > 0, "PlatformImage should have valid width")
        #expect(platformImage.size.height > 0, "PlatformImage should have valid height")
        #expect(platformImage.size.width == CGFloat(cgImage.width), "Size should match CGImage width")
        #expect(platformImage.size.height == CGFloat(cgImage.height), "Size should match CGImage height")
        
        #elseif os(macOS)
        // macOS requires size parameter
        let expectedSize = CGSize(width: cgImage.width, height: cgImage.height)
        let platformImage = PlatformImage(cgImage: cgImage, size: expectedSize)
        #expect(platformImage.size.width > 0, "PlatformImage should have valid width")
        #expect(platformImage.size.height > 0, "PlatformImage should have valid height")
        #expect(platformImage.size == expectedSize, "Size should match provided size")
    #endif
    }
    
    /// BUSINESS PURPOSE: Verify CGImage initializer eliminates platform-specific code (Issue #23)
    /// TESTING SCOPE: Tests that CGImage initializer works without platform conditionals
    /// METHODOLOGY: Test cross-platform usage pattern
    @Test func testPlatformImageCGImageCrossPlatformUsage() {
        // Given: A CGImage (same on both platforms)
        // Create a simple test CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let cgImage = context.makeImage()!
        let expectedSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // When: Creating PlatformImage (no platform conditionals needed in user code)
        #if os(iOS)
        // iOS: size is extracted from CGImage automatically
        let platformImage = PlatformImage(cgImage: cgImage)
        #expect(platformImage.size == expectedSize, "iOS should extract size from CGImage")
        #elseif os(macOS)
        // macOS: size parameter required
        let platformImage = PlatformImage(cgImage: cgImage, size: expectedSize)
        #expect(platformImage.size == expectedSize, "macOS should use provided size")
        
        // Then: Both platforms produce usable PlatformImage
        #expect(platformImage.size.width > 0, "PlatformImage should be valid")
        #expect(platformImage.size.height > 0, "PlatformImage should be valid")
    #endif
    }
    
    /// BUSINESS PURPOSE: Verify CGImage initializer with default size on macOS (Issue #23)
    /// TESTING SCOPE: Tests macOS initializer with default size parameter
    /// METHODOLOGY: Test default size behavior
    @Test func testPlatformImageCGImageDefaultSize() {
        #if os(macOS)
        // Given: A CGImage
        // Create a simple test CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: 100, height: 100, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let cgImage = context.makeImage()!
        
        // When: Creating PlatformImage with default size (.zero)
        let platformImage = PlatformImage(cgImage: cgImage, size: .zero)
        #expect(!platformImage.isEmpty, "CGImage init with .zero size uses CGImage dimensions")
        #expect(platformImage.size == CGSize(width: 100, height: 100), "CGImage .zero size resolves to 100×100")
        #endif
    }

    /// `init?(data:)` forwards to UIImage/NSImage. A truncated JPEG header is not a shared contract.
    private func expectTruncatedJPEGHeaderMatchesPlatformDecoder() {
        let truncatedJPEGHeader = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let image = PlatformImage(data: truncatedJPEGHeader)
        #if os(macOS)
        #expect(image != nil, "NSImage accepts a truncated JPEG header")
        #expect(image?.isEmpty == true, "Accepted truncated JPEG has zero size")
        #else
        #expect(image == nil, "UIImage rejects a truncated JPEG header")
        #endif
    }
    
}
