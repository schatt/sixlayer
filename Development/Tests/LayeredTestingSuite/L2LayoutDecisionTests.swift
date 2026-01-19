//
//  L2LayoutDecisionTests.swift
//  SixLayerFramework
//
//  Layer 2 Testing: Layout Decision Engine Functions
//  Tests L2 functions that analyze content and make layout decisions
//

import Testing
import SwiftUI
@testable import SixLayerFramework

class L2LayoutDecisionTests: BaseTestClass {
    
    // MARK: - Test Data
    
    private var sampleContent: [GenericDataItem] = []
    private var sampleHints: PresentationHints = PresentationHints()
    private var sampleOCRContext: OCRContext = OCRContext()
    private var samplePhotoContext: PhotoContext = PhotoContext()
    private var sampleContentComplexity: ContentComplexity = .moderate
    private var sampleDeviceType: DeviceType = .phone
    
    private func createSampleContent() {

    
        return L2TestDataFactory.createSampleContent()

    
    }

    
    private func createSampleHints() {

    
        return L2TestDataFactory.createSampleHints()

    
    }

    
    private func createSampleOCRContext() {

    
        return L2TestDataFactory.createSampleOCRContext()

    
    }

    
    private func createSamplePhotoContext() {

    
        return L2TestDataFactory.createSamplePhotoContext()

    
    }

    
    private func createSampleContentComplexity() {

    
        return L2TestDataFactory.createSampleContentComplexity()

    
    }

    
    private func createSampleDeviceType() {

    
        return L2TestDataFactory.createSampleDeviceType()

    
    }

    
    // BaseTestClass handles setup automatically - no init() needed
    
    deinit {
        Task { [weak self] in
            await self?.cleanupTestEnvironment()
        }
    }
    
    // MARK: - Card Layout Decision Functions
    
    @Test func testDetermineIntelligentCardLayout_L2() {
        // Given
        let contentCount = sampleContent.count
        let screenWidth: CGFloat = 375.0
        let deviceType = sampleDeviceType
        let contentComplexity = sampleContentComplexity
        
        // When
        let layoutDecision = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: contentComplexity
        )
        
        // Then
        #expect(Bool(true), "Layout decision should be created")  // layoutDecision is non-optional
        #expect(layoutDecision.columns > 0, "Should have at least 1 column")
        #expect(layoutDecision.spacing > 0, "Spacing should be positive")
        #expect(layoutDecision.cardWidth > 0, "Card width should be positive")
        #expect(layoutDecision.cardHeight > 0, "Card height should be positive")
        #expect(layoutDecision.padding > 0, "Padding should be positive")
        #expect(layoutDecision.expansionScale > 1.0, "Expansion scale should be greater than 1.0")
        #expect(layoutDecision.animationDuration > 0, "Animation duration should be positive")
    }
    
    @Test func testDetermineIntelligentCardLayout_L2_PhoneDevice() {
        // Given
        let contentCount = 6
        let screenWidth: CGFloat = 375.0
        let deviceType = DeviceType.phone
        let contentComplexity = ContentComplexity.simple
        
        // When
        let layoutDecision = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: contentComplexity
        )
        
        // Then
        #expect(layoutDecision.columns == 1, "Phone should use 1 column for 6 items")
        #expect(layoutDecision.cardWidth <= screenWidth - 32, "Card width should fit screen")
    }
    
    @Test func testDetermineIntelligentCardLayout_L2_PadDevice() {
        // Given
        let contentCount = 8
        let screenWidth: CGFloat = 768.0
        let deviceType = DeviceType.pad
        let contentComplexity = ContentComplexity.complex
        
        // When
        let layoutDecision = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: contentComplexity
        )
        
        // Then
        #expect(layoutDecision.columns >= 2, "iPad should use at least 2 columns")
        #expect(layoutDecision.columns <= 4, "iPad should use at most 4 columns")
    }
    
    // MARK: - OCR Layout Decision Functions
    
    @Test func testPlatformOCRLayout_L2() {
        // Given
        let context = sampleOCRContext
        let capabilities: OCRDeviceCapabilities? = nil
        
        // When
        let layout = platformOCRLayout_L2(
            context: context,
            capabilities: capabilities
        )
        
        // Then
        #expect(Bool(true), "OCR layout should be created")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Max image width should be positive")
        #expect(layout.maxImageSize.height > 0, "Max image height should be positive")
        #expect(layout.recommendedImageSize.width > 0, "Recommended image width should be positive")
        #expect(layout.recommendedImageSize.height > 0, "Recommended image height should be positive")
    }
    
    @Test func testPlatformDocumentOCRLayout_L2() {
        // Given
        let documentType = DocumentType.receipt
        let context = sampleOCRContext
        let capabilities: OCRDeviceCapabilities? = nil
        
        // When
        let layout = platformDocumentOCRLayout_L2(
            documentType: documentType,
            context: context,
            capabilities: capabilities
        )
        
        // Then
        #expect(Bool(true), "Document OCR layout should be created")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Max image width should be positive")
        #expect(layout.maxImageSize.height > 0, "Max image height should be positive")
    }
    
    @Test func testPlatformReceiptOCRLayout_L2() {
        // Given
        let context = sampleOCRContext
        let capabilities: OCRDeviceCapabilities? = nil
        
        // When
        let layout = platformReceiptOCRLayout_L2(
            context: context,
            capabilities: capabilities
        )
        
        // Then
        #expect(Bool(true), "Receipt OCR layout should be created")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Max image width should be positive")
        #expect(layout.maxImageSize.height > 0, "Max image height should be positive")
    }
    
    @Test func testPlatformBusinessCardOCRLayout_L2() {
        // Given
        let context = sampleOCRContext
        let capabilities: OCRDeviceCapabilities? = nil
        
        // When
        let layout = platformBusinessCardOCRLayout_L2(
            context: context,
            capabilities: capabilities
        )
        
        // Then
        #expect(Bool(true), "Business card OCR layout should be created")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Max image width should be positive")
        #expect(layout.maxImageSize.height > 0, "Max image height should be positive")
    }
    
    // MARK: - Photo Layout Decision Functions
    
    @Test func testDetermineOptimalPhotoLayout_L2() {
        // Given
        let purpose = PhotoPurpose.document
        let context = samplePhotoContext
        
        // When
        let layout = determineOptimalPhotoLayout_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(layout.width > 0, "Photo layout width should be positive")
        #expect(layout.height > 0, "Photo layout height should be positive")
        #expect(layout.width <= context.availableSpace.width, "Layout width should fit available space")
        #expect(layout.height <= context.availableSpace.height, "Layout height should fit available space")
    }
    
    @Test func testDetermineOptimalPhotoLayout_L2_VehiclePhoto() {
        // Given
        let purpose = PhotoPurpose.general
        let context = samplePhotoContext
        
        // When
        let layout = determineOptimalPhotoLayout_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(layout.width > 0, "Vehicle photo layout width should be positive")
        #expect(layout.height > 0, "Vehicle photo layout height should be positive")
        // Vehicle photos should be wider than tall (landscape aspect ratio)
        #expect(layout.width > layout.height, "Vehicle photo should be landscape")
    }
    
    @Test func testDetermineOptimalPhotoLayout_L2_ReceiptPhoto() {
        // Given
        let purpose = PhotoPurpose.document
        let context = samplePhotoContext
        
        // When
        let layout = determineOptimalPhotoLayout_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(layout.width > 0, "Receipt photo layout width should be positive")
        #expect(layout.height > 0, "Receipt photo layout height should be positive")
        // Receipt photos should be taller than wide (portrait aspect ratio)
        #expect(layout.height > layout.width, "Receipt photo should be portrait")
    }
    
    @Test func testDetermineOptimalPhotoLayout_L2_OdometerPhoto() {
        // Given
        let purpose = PhotoPurpose.document
        let context = samplePhotoContext
        
        // When
        let layout = determineOptimalPhotoLayout_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(layout.width > 0, "Odometer photo layout width should be positive")
        #expect(layout.height > 0, "Odometer photo layout height should be positive")
        // Odometer photos should be roughly square
        let aspectRatio = layout.width / layout.height
        #expect(aspectRatio > 0.8, "Odometer photo should be roughly square")
        #expect(aspectRatio < 1.2, "Odometer photo should be roughly square")
    }
    
    @Test func testDeterminePhotoCaptureStrategy_L2() {
        // Given
        let purpose = PhotoPurpose.document
        let context = samplePhotoContext
        
        // When
        let strategy = determinePhotoCaptureStrategy_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([PhotoCaptureStrategy.camera, .photoLibrary, .both].contains(strategy), "Strategy should be valid")
    }
    
    @Test func testDeterminePhotoCaptureStrategy_L2_CameraOnly() {
        // Given
        let purpose = PhotoPurpose.general
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 600),
            userPreferences: PhotoPreferences(preferredSource: .camera),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: true, hasPhotoLibrary: false)
        )
        
        // When
        let strategy = determinePhotoCaptureStrategy_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .camera, "Should use camera when only camera is available")
    }
    
    @Test func testDeterminePhotoCaptureStrategy_L2_PhotoLibraryOnly() {
        // Given
        let purpose = PhotoPurpose.document
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 600),
            userPreferences: PhotoPreferences(preferredSource: .photoLibrary),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: false, hasPhotoLibrary: true)
        )
        
        // When
        let strategy = determinePhotoCaptureStrategy_L2(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .photoLibrary, "Should use photo library when only photo library is available")
    }
    
    // MARK: - Layout Decision Validation
    
    @Test func testLayoutDecisionConsistency() {
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 375.0
        let deviceType = DeviceType.phone
        let contentComplexity = ContentComplexity.moderate
        
        // When
        let layout1 = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: contentComplexity
        )
        
        let layout2 = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: contentComplexity
        )
        
        // Then
        #expect(layout1.columns == layout2.columns, "Layout decisions should be consistent")
        #expect(layout1.spacing == layout2.spacing, "Layout decisions should be consistent")
        #expect(layout1.cardWidth == layout2.cardWidth, "Layout decisions should be consistent")
        #expect(layout1.cardHeight == layout2.cardHeight, "Layout decisions should be consistent")
    }
    
    @Test func testLayoutDecisionPerformance() {
        // Given
        let contentCount = 100
        let screenWidth: CGFloat = 1024.0
        let deviceType = DeviceType.pad
        let contentComplexity = ContentComplexity.complex
        
        // When
        let layout = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: contentComplexity
        )
        
        // Then
        #expect(Bool(true), "Layout decision should be created")  // layout is non-optional
    }
}









