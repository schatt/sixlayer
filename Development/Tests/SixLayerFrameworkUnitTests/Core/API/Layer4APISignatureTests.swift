import Testing

//
//  Layer4APISignatureTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates ALL public Layer 4 API signatures to prevent breaking changes.
//  These tests would have caught API signature changes that violate semantic versioning.
//
//  TESTING SCOPE:
//  - All public Layer 4 function signatures and parameter labels
//  - API compatibility and backward compatibility
//  - Parameter label requirements and optional parameters
//  - Cross-platform API consistency
//  - Breaking change detection for public interface
//
//  METHODOLOGY:
//  - Test every public Layer 4 function signature exists
//  - Test parameter labels are correct and required
//  - Test backward compatibility with old API patterns
//  - Test cross-platform API consistency
//  - Test that API changes would break these tests
//
//  CRITICAL: These tests MUST fail if any public API signature changes
//

import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
#if canImport(MapKit)
import MapKit
#endif
@testable import SixLayerFramework


/// NOTE: Not marked @MainActor on class to allow parallel execution
open class Layer4APISignatureTests: BaseTestClass {
    
    // MARK: - Photo Components API Tests
    
    /// BUSINESS PURPOSE: Verify platformPhotoPicker_L4 API signature exists and works
    /// TESTING SCOPE: Tests that platformPhotoPicker_L4 accepts correct callback signature
    /// METHODOLOGY: Test API signature compiles and accepts PlatformImage callback
    @Test @MainActor func testPlatformPhotoPicker_L4_APISignature() {
        // Given: A callback function with correct signature
        let callback: (PlatformImage) -> Void = { _ in }
        
        // When: Calling the API
        let _ = platformPhotoPicker_L4(onImageSelected: callback)
        
        // Then: API should accept the callback (compile-time check)
        #expect(Bool(true), "platformPhotoPicker_L4 should accept PlatformImage callback")
    }
    
    /// BUSINESS PURPOSE: Verify platformCameraInterface_L4 API signature exists and works
    /// TESTING SCOPE: Tests that platformCameraInterface_L4 accepts correct callback signature
    /// METHODOLOGY: Test API signature compiles and accepts PlatformImage callback
    @Test @MainActor func testPlatformCameraInterface_L4_APISignature() {
        // Given: A callback function with correct signature
        let callback: (PlatformImage) -> Void = { _ in }
        
        // When: Calling the API
        let _ = platformCameraInterface_L4(onImageCaptured: callback)
        
        // Then: API should accept the callback (compile-time check)
        #expect(Bool(true), "platformCameraInterface_L4 should accept PlatformImage callback")
    }
    
    /// BUSINESS PURPOSE: Verify platformPhotoDisplay_L4 API signature exists and works
    /// TESTING SCOPE: Tests that platformPhotoDisplay_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @Test @MainActor func testPlatformPhotoDisplay_L4_APISignature() {
        // Given: Test image and style
        let testImage = PlatformImage.createPlaceholder()
        let style = PhotoDisplayStyle.aspectFit
        
        // When: Calling the API
        let _ = platformPhotoDisplay_L4(image: testImage, style: style)
        
        // Then: API should accept the parameters (compile-time check)
        #expect(Bool(true), "platformPhotoDisplay_L4 should accept PlatformImage and PhotoDisplayStyle")
    }
    
    /// BUSINESS PURPOSE: Verify platformPhotoDisplay_L4 accepts nil image
    /// TESTING SCOPE: Tests that platformPhotoDisplay_L4 accepts optional PlatformImage
    /// METHODOLOGY: Test API signature with nil image parameter
    @Test @MainActor func testPlatformPhotoDisplay_L4_NilImage() {
        // Given: Nil image and style
        let style = PhotoDisplayStyle.aspectFit
        
        // When: Calling the API with nil image
        let _ = platformPhotoDisplay_L4(image: nil, style: style)
        
        // Then: API should accept nil image (compile-time check)
        #expect(Bool(true), "platformPhotoDisplay_L4 should accept optional PlatformImage")
    }
    
    // MARK: - Print API Tests
    
    /// BUSINESS PURPOSE: Verify platformPrint_L4 API signature exists and works
    /// TESTING SCOPE: Tests that platformPrint_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @Test @MainActor func testPlatformPrint_L4_APISignature() {
        // Given: Print content
        let content = PrintContent.text("Test content")
        
        // When: Calling the API without options
        let result = platformPrint_L4(content: content)
        
        // Then: API should return Bool (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformPrint_L4 should return Bool")
    }
    
    /// BUSINESS PURPOSE: Verify platformPrint_L4 accepts optional options parameter
    /// TESTING SCOPE: Tests that platformPrint_L4 accepts optional PrintOptions
    /// METHODOLOGY: Test API signature with optional parameter
    @Test @MainActor func testPlatformPrint_L4_WithOptions() {
        // Given: Print content and options
        let content = PrintContent.text("Test content")
        let options = PrintOptions()
        
        // When: Calling the API with options
        let result = platformPrint_L4(content: content, options: options)
        
        // Then: API should accept optional options (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformPrint_L4 should accept optional PrintOptions")
    }
    
    /// BUSINESS PURPOSE: Verify platformPrint_L4 accepts nil options
    /// TESTING SCOPE: Tests that platformPrint_L4 accepts nil for optional parameter
    /// METHODOLOGY: Test API signature with nil optional parameter
    @Test @MainActor func testPlatformPrint_L4_WithNilOptions() {
        // Given: Print content
        let content = PrintContent.text("Test content")
        
        // When: Calling the API with nil options
        let result = platformPrint_L4(content: content, options: nil)
        
        // Then: API should accept nil options (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformPrint_L4 should accept nil for optional PrintOptions")
    }
    
    // MARK: - OCR Components API Tests
    
    // NOTE: Tests for deprecated OCR APIs intentionally use deprecated functions to verify backward compatibility.
    // Deprecation warnings are expected and acceptable in those specific tests.
    
    /// BUSINESS PURPOSE: Verify OCRService.processImage() API signature exists and works
    /// TESTING SCOPE: Tests that OCRService.processImage() accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @Test func testOCRService_processImage_APISignature() async throws {
        // Given: Test image, context, and strategy
        let _ = PlatformImage.createPlaceholder()
        let _ = OCRContext()
        let _ = OCRStrategy(
            supportedTextTypes: [.general],
            supportedLanguages: [.english],
            processingMode: .standard
        )
        let service = OCRService()
        
        // When: Calling the new API (may throw, but signature is what we're testing)
        // Note: We're testing the signature, not the functionality
        // The signature is: func processImage(_ image: PlatformImage, context: OCRContext, strategy: OCRStrategy) async throws -> OCRResult
        let processFunction: (PlatformImage, OCRContext, OCRStrategy) async throws -> OCRResult = service.processImage
        
        // Verify the function signature matches expected types (compile-time check)
        let _: (PlatformImage, OCRContext, OCRStrategy) async throws -> OCRResult = processFunction
        
        // Then: API should accept the parameters (compile-time check)
        #expect(Bool(true), "OCRService.processImage() should accept correct parameters")
    }
    
    // MARK: - Map Components API Tests
    
    /// BUSINESS PURPOSE: Verify platformMapView_L4 API signature exists (with MapContentBuilder)
    /// TESTING SCOPE: Tests that platformMapView_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test @MainActor func testPlatformMapView_L4_WithMapContentBuilder_APISignature() {
        #if canImport(MapKit)
        // Given: Binding position and content builder
        let position = Binding<MapCameraPosition>(
            get: { MapCameraPosition.automatic },
            set: { (_: MapCameraPosition) in }
        )
        
        // When: Calling the API with MapContentBuilder
        let _ = platformMapView_L4(position: position) {
            // Empty content builder
        }
        
        // Then: API should accept the parameters (compile-time check)
        #expect(Bool(true), "platformMapView_L4 should accept Binding<MapCameraPosition> and MapContentBuilder")
        #else
        // Skip test if MapKit is not available
        #expect(Bool(true), "MapKit not available on this platform")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify platformMapView_L4 API signature exists (with annotations)
    /// TESTING SCOPE: Tests that platformMapView_L4 accepts annotations parameter
    /// METHODOLOGY: Test API signature compiles with annotations parameter
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test @MainActor func testPlatformMapView_L4_WithAnnotations_APISignature() {
        #if canImport(MapKit)
        // Given: Binding position, annotations, and optional callback
        let position = Binding<MapCameraPosition>(
            get: { MapCameraPosition.automatic },
            set: { (_: MapCameraPosition) in }
        )
        let annotations: [MapAnnotationData] = []
        let callback: ((MapAnnotationData) -> Void)? = nil
        
        // When: Calling the API with annotations
        let _ = platformMapView_L4(
            position: position,
            annotations: annotations,
            onAnnotationTapped: callback
        )
        
        // Then: API should accept the parameters (compile-time check)
        #expect(Bool(true), "platformMapView_L4 should accept annotations and optional callback")
        #else
        // Skip test if MapKit is not available
        #expect(Bool(true), "MapKit not available on this platform")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify platformMapViewWithCurrentLocation_L4 API signature exists
    /// TESTING SCOPE: Tests that platformMapViewWithCurrentLocation_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test @MainActor func testPlatformMapViewWithCurrentLocation_L4_APISignature() {
        // Given: Location service and optional parameters
        let locationService = LocationService()
        
        // When: Calling the API with default parameters
        let _ = platformMapViewWithCurrentLocation_L4(
            locationService: locationService,
            showCurrentLocation: true
        )
        
        // Then: API should accept the parameters (compile-time check)
        #expect(Bool(true), "platformMapViewWithCurrentLocation_L4 should accept LocationService and optional parameters")
    }
    
    // MARK: - Share/Clipboard API Tests
    
    /// BUSINESS PURPOSE: Verify platformCopyToClipboard_L4 API signature exists and works
    /// TESTING SCOPE: Tests that platformCopyToClipboard_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @Test @MainActor func testPlatformCopyToClipboard_L4_APISignature() {
        // Given: Content to copy
        let content = "Test string"
        
        // When: Calling the API without feedback parameter
        let result = platformCopyToClipboard_L4(content: content)
        
        // Then: API should return Bool (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformCopyToClipboard_L4 should return Bool")
    }
    
    /// BUSINESS PURPOSE: Verify platformCopyToClipboard_L4 accepts optional provideFeedback parameter
    /// TESTING SCOPE: Tests that platformCopyToClipboard_L4 accepts optional provideFeedback
    /// METHODOLOGY: Test API signature with optional parameter
    @Test @MainActor func testPlatformCopyToClipboard_L4_WithFeedback() {
        // Given: Content to copy
        let content = "Test string"
        
        // When: Calling the API with feedback parameter
        let result = platformCopyToClipboard_L4(content: content, provideFeedback: true)
        
        // Then: API should accept optional provideFeedback (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformCopyToClipboard_L4 should accept optional provideFeedback parameter")
    }
    
    /// BUSINESS PURPOSE: Verify platformCopyToClipboard_L4 accepts PlatformImage
    /// TESTING SCOPE: Tests that platformCopyToClipboard_L4 accepts PlatformImage content
    /// METHODOLOGY: Test API signature with PlatformImage parameter
    @Test @MainActor func testPlatformCopyToClipboard_L4_WithPlatformImage() {
        // Given: PlatformImage content
        let content = PlatformImage.createPlaceholder()
        
        // When: Calling the API with PlatformImage
        let result = platformCopyToClipboard_L4(content: content)
        
        // Then: API should accept PlatformImage (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformCopyToClipboard_L4 should accept PlatformImage content")
    }
    
    /// BUSINESS PURPOSE: Verify platformOpenURL_L4 API signature exists and works
    /// TESTING SCOPE: Tests that platformOpenURL_L4 accepts URL parameter
    /// METHODOLOGY: Test API signature compiles with correct parameter type
    /// 
    /// NOTE: The implementation includes test environment detection to prevent
    /// actually opening URLs during tests. This test verifies the API signature
    /// without triggering actual URL opening behavior.
    @Test @MainActor func testPlatformOpenURL_L4_APISignature() {
        // Given: A URL
        let url = URL(string: "https://example.com")!
        
        // When: Calling the API
        // NOTE: Implementation detects test environment and returns true without opening
        let result = platformOpenURL_L4(url)
        
        // Then: API should return Bool (compile-time check)
        let _: Bool = result
        #expect(Bool(true), "platformOpenURL_L4 should return Bool")
        // Verify test environment protection works (should return true without opening)
        #expect(result == true, "platformOpenURL_L4 should return true in test environment without opening URL")
    }
    
    // MARK: - Navigation Stack API Tests
    
    /// BUSINESS PURPOSE: Verify platformImplementNavigationStack_L4 API signature exists
    /// TESTING SCOPE: Tests that platformImplementNavigationStack_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @Test @MainActor func testPlatformImplementNavigationStack_L4_APISignature() {
        // Given: Content view
        let content = Text("Test")
        let strategy = NavigationStackStrategy(
            implementation: nil,
            reasoning: nil
        )
        
        // When: Calling the API
        let _ = platformImplementNavigationStack_L4(
            content: content,
            title: nil,
            strategy: strategy
        )
        
        // Then: API should accept content (compile-time check)
        #expect(Bool(true), "platformImplementNavigationStack_L4 should accept View content")
    }
    
    /// BUSINESS PURPOSE: Verify platformImplementNavigationStackItems_L4 API signature exists
    /// TESTING SCOPE: Tests that platformImplementNavigationStackItems_L4 accepts correct parameters
    /// METHODOLOGY: Test API signature compiles with correct parameter types
    @Test @MainActor func testPlatformImplementNavigationStackItems_L4_APISignature() {
        // Given: Test items and callbacks
        struct TestItem: Identifiable & Hashable {
            let id = UUID()
        }
        let items: [TestItem] = []
        let selectedItem = Binding<TestItem?>(
            get: { nil },
            set: { _ in }
        )
        let itemView: (TestItem) -> AnyView = { item in
            AnyView(Text("Item \(item.id.uuidString)"))
        }
        let detailView: (TestItem) -> AnyView = { item in
            AnyView(Text("Detail \(item.id.uuidString)"))
        }
        let strategy = NavigationStackStrategy(
            implementation: nil,
            reasoning: nil
        )
        
        // When: Calling the API
        let _ = platformImplementNavigationStackItems_L4(
            items: items,
            selectedItem: selectedItem,
            itemView: itemView,
            detailView: detailView,
            strategy: strategy
        )
        
        // Then: API should accept the parameters (compile-time check)
        #expect(Bool(true), "platformImplementNavigationStackItems_L4 should accept items and callbacks")
    }
    
    
    // MARK: - Breaking Change Detection Tests
    
    /// BUSINESS PURPOSE: Verify photo picker callback parameter type (breaking change detection)
    /// TESTING SCOPE: Tests that callback parameter is PlatformImage, not platform-specific type
    /// METHODOLOGY: Test exact callback signature that would break if changed
    @Test @MainActor func testPlatformPhotoPicker_L4_CallbackParameterType() {
        // Given: Callback that expects PlatformImage (not UIImage/NSImage)
        var capturedImage: PlatformImage?
        let callback: (PlatformImage) -> Void = { image in
            capturedImage = image  // This would fail if parameter type changed
        }
        
        // When: Creating the view with callback
        let _ = platformPhotoPicker_L4(onImageSelected: callback)
        
        // Then: Callback signature should be PlatformImage (compile-time check)
        #expect(Bool(true), "platformPhotoPicker_L4 callback should accept PlatformImage parameter")
        
        // Test callback directly to verify it works
        let testImage = PlatformImage.createPlaceholder()
        callback(testImage)
        #expect(capturedImage != nil, "Callback should capture PlatformImage")
    }
    
    /// BUSINESS PURPOSE: Verify camera interface callback parameter type (breaking change detection)
    /// TESTING SCOPE: Tests that callback parameter is PlatformImage, not platform-specific type
    /// METHODOLOGY: Test exact callback signature that would break if changed
    @Test @MainActor func testPlatformCameraInterface_L4_CallbackParameterType() {
        // Given: Callback that expects PlatformImage (not UIImage/NSImage)
        var capturedImage: PlatformImage?
        let callback: (PlatformImage) -> Void = { image in
            capturedImage = image  // This would fail if parameter type changed
        }
        
        // When: Creating the view with callback
        let _ = platformCameraInterface_L4(onImageCaptured: callback)
        
        // Then: Callback signature should be PlatformImage (compile-time check)
        #expect(Bool(true), "platformCameraInterface_L4 callback should accept PlatformImage parameter")
        
        // Test callback directly to verify it works
        let testImage = PlatformImage.createPlaceholder()
        callback(testImage)
        #expect(capturedImage != nil, "Callback should capture PlatformImage")
    }
    
}

