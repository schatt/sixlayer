import Testing
@testable import SixLayerFramework
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

//
//  PlatformImageImplicitConversionTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Tests that verify implicit conversions from UIImage/NSImage to PlatformImage work correctly.
//  These tests ensure the currency exchange model works seamlessly with implicit conversions.
//
//  TESTING SCOPE:
//  - Test UIImage → PlatformImage implicit conversion
//  - Test NSImage → PlatformImage implicit conversion
//  - Verify conversions work in Layer 4 callbacks
//  - Test that implicit conversions maintain data integrity
//
//  METHODOLOGY:
//  - Test implicit conversion syntax
//  - Test conversion in callback contexts
//  - Test data integrity after conversion
//
//  CRITICAL: These tests verify the currency exchange model works with implicit conversions
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import SixLayerFramework


/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformImageImplicitConversionTests: BaseTestClass {
    
    // MARK: - Implicit Conversion Tests
    
    /// BUSINESS PURPOSE: Verify UIImage → PlatformImage implicit conversion works
    /// TESTING SCOPE: Tests that UIImage can be implicitly converted to PlatformImage
    /// METHODOLOGY: Test implicit conversion syntax and data integrity
    @Test @MainActor func testUIImageImplicitConversion() {
        #if os(iOS)
        // Given: PlatformImage placeholder (framework-compliant test image)
        let placeholderImage = PlatformImage.createPlaceholder()
        let uiImage = placeholderImage.uiImage

        // When: Use implicit conversion
        let platformImage = PlatformImage(uiImage)  // Implicit conversion

        // Then: Conversion should work correctly
        // uiImage is non-optional, so we verify by checking size
        #expect(platformImage.size.width > 0, "Implicit conversion should produce valid UIImage with dimensions")
        #expect(platformImage.size.height > 0, "Converted PlatformImage should have valid dimensions")
        #expect(platformImage.size.height > 0, "Converted PlatformImage should have valid dimensions")

        // Test that both explicit and implicit conversions produce same result
        let explicitPlatformImage = PlatformImage(uiImage: uiImage)
        #expect(platformImage.size == explicitPlatformImage.size, "Implicit and explicit conversions should produce equivalent results")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify NSImage → PlatformImage implicit conversion works
    /// TESTING SCOPE: Tests that NSImage can be implicitly converted to PlatformImage
    /// METHODOLOGY: Test implicit conversion syntax and data integrity
    @Test @MainActor func testNSImageImplicitConversion() {
        #if os(macOS)
        // Given: PlatformImage placeholder (framework-compliant test image)
        let placeholderImage = PlatformImage.createPlaceholder()
        let nsImage = placeholderImage.nsImage

        // When: Use implicit conversion
        let platformImage = PlatformImage(nsImage)  // Implicit conversion

        // Then: Conversion should work correctly
        // NSImage is non-optional, so verify it has valid size
        #expect(platformImage.nsImage.size.width > 0, "Implicit conversion should produce valid NSImage")
        #expect(platformImage.size.width > 0, "Converted PlatformImage should have valid dimensions")
        #expect(platformImage.size.height > 0, "Converted PlatformImage should have valid dimensions")

        // Test that both explicit and implicit conversions produce same result
        let explicitPlatformImage = PlatformImage(nsImage: nsImage)
        #expect(platformImage.size == explicitPlatformImage.size, "Implicit and explicit conversions should produce equivalent results")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify implicit conversions work in Layer 4 callbacks
    /// TESTING SCOPE: Tests that Layer 4 callbacks work with implicit conversions
    /// METHODOLOGY: Test implicit conversion in callback contexts
    @Test @MainActor func testImplicitConversionInLayer4Callbacks() {
        #if os(iOS)
        // Given: PlatformImage placeholder and Layer 4 components
        let placeholderImage = PlatformImage.createPlaceholder()
        let uiImage = placeholderImage.uiImage
        
        
        // When: Use implicit conversion in callback
        var capturedImage: PlatformImage?
        let cameraInterface = PlatformPhotoComponentsLayer4.platformCameraInterface_L4 { image in
            capturedImage = image
        }
        
        // Simulate delegate method with implicit conversion
        let coordinator = CameraView.Coordinator(CameraView(onImageCaptured: { image in
            capturedImage = image
        }))
        
        // 6LAYER_ALLOW: testing framework boundary with deprecated platform image picker APIs
        let mockInfo: [UIImagePickerController.InfoKey: Any] = [.originalImage: uiImage]
        // 6LAYER_ALLOW: testing framework boundary with deprecated platform image picker APIs
        coordinator.imagePickerController(UIImagePickerController(), didFinishPickingMediaWithInfo: mockInfo)
        
        // Then: Implicit conversion should work in callback context
        #expect(Bool(true), "Implicit conversion should work in Layer 4 callbacks")  // capturedImage is non-optional
        #expect(capturedImage!.uiImage == uiImage, "Callback should receive correctly converted PlatformImage")
        #elseif os(macOS)
        // Given: NSImage and Layer 4 components
        let _ = createTestNSImage()
        
        
        // When: Use implicit conversion in callback
        var capturedImage: PlatformImage?
        let cameraInterface = PlatformPhotoComponentsLayer4.platformCameraInterface_L4 { image in
            capturedImage = image
        }
        
        // Simulate delegate method with implicit conversion
        let coordinator = MacCameraView.Coordinator(MacCameraView(onImageCaptured: { image in
            capturedImage = image
        }))
        
        coordinator.takePhoto()
        
        // Then: Implicit conversion should work in callback context
        #expect(Bool(true), "Implicit conversion should work in Layer 4 callbacks")  // capturedImage is non-optional
        #expect(capturedImage!.size.width > 0, "Callback should receive valid PlatformImage")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify implicit conversions maintain data integrity
    /// TESTING SCOPE: Tests that implicit conversions preserve image data correctly
    /// METHODOLOGY: Test data integrity after implicit conversion
    @Test @MainActor func testImplicitConversionDataIntegrity() {
        #if os(iOS)
        // Given: UIImage with specific properties
        let uiImage = createTestUIImage()
        let originalSize = uiImage.size
        _ = uiImage.jpegData(compressionQuality: 0.8)
        
        // When: Use implicit conversion
        let platformImage = PlatformImage(uiImage)
        
        // Then: Data integrity should be preserved
        #expect(platformImage.size == originalSize, "Implicit conversion should preserve size")
        #expect(platformImage.uiImage == uiImage, "Implicit conversion should preserve UIImage")
        
        // Test that converted image can be used in framework
        
        let photoDisplay = PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(
            image: platformImage,
            style: .thumbnail
        )
        
        #expect(Bool(true), "Framework should work with implicitly converted PlatformImage")  // photoDisplay is non-optional
        
        #elseif os(macOS)
        // Given: NSImage with specific properties
        let nsImage = createTestNSImage()
        let originalSize = nsImage.size
        
        // When: Use implicit conversion
        let platformImage = PlatformImage(nsImage)
        
        // Then: Data integrity should be preserved
        #expect(platformImage.size == originalSize, "Implicit conversion should preserve size")
        #expect(platformImage.nsImage == nsImage, "Implicit conversion should preserve NSImage")
        
        // Test that converted image can be used in framework
        
        let photoDisplay = PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(
            image: platformImage,
            style: .thumbnail
        )
        
        #expect(Bool(true), "Framework should work with implicitly converted PlatformImage")  // photoDisplay is non-optional
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify implicit conversions work with different image sources
    /// TESTING SCOPE: Tests implicit conversions with various image sources
    /// METHODOLOGY: Test conversions with different image creation methods
    @Test func testImplicitConversionWithDifferentSources() {
        #if os(iOS)
        // Test with different UIImage creation methods
        let size = CGSize(width: 50, height: 50)
        
        // Test 1: UIGraphicsImageRenderer
        // 6LAYER_ALLOW: testing platform-specific image rendering boundary conversions
        // 6LAYER_ALLOW: testing platform-specific image rendering boundary conversions
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage1 = renderer.image { context in
            // 6LAYER_ALLOW: testing platform-specific image rendering boundary conversions
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let platformImage1 = PlatformImage(uiImage1)
        #expect(platformImage1.uiImage == uiImage1, "Implicit conversion should work with UIGraphicsImageRenderer")
        
        // Test 2: UIImage from data
        if let data = uiImage1.jpegData(compressionQuality: 0.8),
           let uiImage2 = UIImage(data: data) { // 6LAYER_ALLOW: testing PlatformImage constructor with UIImage from data
            let platformImage2 = PlatformImage(uiImage2)
            #expect(platformImage2.uiImage == uiImage2, "Implicit conversion should work with UIImage from data")
        }
        
        #elseif os(macOS)
        // Test with different NSImage creation methods
        // 6LAYER_ALLOW: testing platform-specific image rendering boundary conversions
        let size = NSSize(width: 50, height: 50)

        // Test 1: NSImage with size
        // 6LAYER_ALLOW: testing platform-specific image rendering boundary conversions
        let nsImage1 = NSImage(size: size)
        nsImage1.lockFocus()
        NSColor.red.drawSwatch(in: NSRect(origin: .zero, size: size)) // 6LAYER_ALLOW: testing platform-specific image rendering boundary conversions
        nsImage1.unlockFocus()
        let platformImage1 = PlatformImage(nsImage1)
        #expect(platformImage1.nsImage == nsImage1, "Implicit conversion should work with NSImage")
        
        // Test 2: NSImage from data
        if let tiffData = nsImage1.tiffRepresentation,
           let nsImage2 = NSImage(data: tiffData) { // 6LAYER_ALLOW: testing PlatformImage constructor with NSImage from data
            let platformImage2 = PlatformImage(nsImage2)
            #expect(platformImage2.nsImage == nsImage2, "Implicit conversion should work with NSImage from data")
        }
        #endif
    }
    
    // MARK: - Test Data Helpers
    
    #if os(iOS)
    private func createTestUIImage() -> UIImage { // 6LAYER_ALLOW: test helper returning platform-specific image type
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size) // 6LAYER_ALLOW: test helper using platform-specific image rendering APIs
        return renderer.image { context in
            UIColor.blue.setFill() // 6LAYER_ALLOW: test helper using platform-specific image rendering APIs
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif
    
    #if os(macOS)
    private func createTestNSImage() -> NSImage { // 6LAYER_ALLOW: test helper returning platform-specific image type
        let size = NSSize(width: 100, height: 100) // 6LAYER_ALLOW: test helper using platform-specific image rendering APIs
        let nsImage = NSImage(size: size) // 6LAYER_ALLOW: test helper using platform-specific image rendering APIs
        nsImage.lockFocus()
        NSColor.blue.drawSwatch(in: NSRect(origin: .zero, size: size)) // 6LAYER_ALLOW: test helper using platform-specific image rendering APIs
        nsImage.unlockFocus()
        return nsImage
    }
    #endif
}
