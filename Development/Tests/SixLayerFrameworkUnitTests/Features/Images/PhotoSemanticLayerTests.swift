import Testing

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Photo Semantic Layer")
open class PhotoSemanticLayerTests: BaseTestClass {
    
    // MARK: - Layer 1: Semantic Photo Functions Tests
    
    @Test @MainActor func testPlatformPhotoCapture_L1() {
        // Given: Photo purpose and context
        let purpose = PhotoPurpose.general
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 800, height: 600),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: true, hasPhotoLibrary: true)
        )
        
        // When: Creating semantic photo capture interface
        let view = platformPhotoCapture_L1(purpose: purpose, context: context) { _ in }
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAPhotoCapture")
    }
    
    @Test @MainActor func testPlatformPhotoSelection_L1() {
        // Given: Photo purpose and context
        let purpose = PhotoPurpose.document
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 800, height: 600),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: false, hasPhotoLibrary: true)
        )
        
        // When: Creating semantic photo selection interface
        let view = platformPhotoSelection_L1(purpose: purpose, context: context) { _ in }
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAPhotoSelection")
    }
    
    @Test @MainActor func testPlatformPhotoDisplay_L1() {
        // Given: Photo purpose, context, and image
        let purpose = PhotoPurpose.document
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 400, height: 300),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        let testImage = PlatformImage.createPlaceholder()
        
        // When: Creating semantic photo display
        let view = platformPhotoDisplay_L1(purpose: purpose, context: context, image: testImage)
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAPhotoDisplay")
    }
    
    // MARK: - Layer 2: Photo Layout Decision Engine Tests
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2() {
        // Given: Photo context and purpose
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 800, height: 600),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        let purpose = PhotoPurpose.general
        
        // When: Determining optimal layout
        let layout = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then: Layout should be determined
        #expect(layout.width > 0)
        #expect(layout.height > 0)
    }
    
    @Test @MainActor func testDeterminePhotoCaptureStrategy_L2() {
        // Given: Photo context and purpose
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 800, height: 600),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: true, hasPhotoLibrary: true)
        )
        let purpose = PhotoPurpose.reference
        
        // When: Determining capture strategy
        let strategy = determinePhotoCaptureStrategy_L2(purpose: purpose, context: context)
        
        // Then
        #expect(strategy == .photoLibrary)
    }
    
    // MARK: - Layer 3: Photo Strategy Selection Tests
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3() {
        // Given: Photo context and purpose
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 800, height: 600),
            userPreferences: PhotoPreferences(preferredSource: .camera),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: true, hasPhotoLibrary: true)
        )
        let purpose = PhotoPurpose.reference
        
        // When: Selecting capture strategy
        let strategy = selectPhotoCaptureStrategy_L3(purpose: purpose, context: context)
        
        // Then
        #expect(strategy == .camera)
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3() {
        // Given: Photo context and purpose
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 400, height: 300),
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        let purpose = PhotoPurpose.document
        
        // When: Selecting display strategy
        let strategy = selectPhotoDisplayStrategy_L3(purpose: purpose, context: context)
        
        // Then
        #expect(strategy == .fullSize)
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testSemanticPhotoWorkflow() {
        // Given: Complete photo workflow context
        let purpose = PhotoPurpose.general
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 800, height: 600),
            userPreferences: PhotoPreferences(preferredSource: .both, allowEditing: true),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: true, hasPhotoLibrary: true, supportsEditing: true)
        )
        
        // When: Running complete semantic workflow
        let layout = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        let captureStrategy = selectPhotoCaptureStrategy_L3(purpose: purpose, context: context)
        let displayStrategy = selectPhotoDisplayStrategy_L3(purpose: purpose, context: context)
        
        // Then: All components should work together
        #expect(layout.width > 0)
        #expect(layout.height > 0)
        #expect(captureStrategy == .camera)
        #expect(displayStrategy == .fullSize)
    }
    
    // MARK: - Helper Methods
    
}
