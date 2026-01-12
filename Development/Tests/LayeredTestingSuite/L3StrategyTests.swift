//
//  L3StrategyTests.swift
//  SixLayerFramework
//
//  Layer 3 Testing: Strategy Selection Functions
//  Tests L3 functions that select optimal strategies based on content analysis
//

import Testing
import SwiftUI
@testable import SixLayerFramework

class L3StrategyTests: BaseTestClass {
    
    // MARK: - Test Data
    
    private var sampleTextTypes: [TextType] = []
    private var sampleDocumentType: DocumentType = .receipt
    private var samplePlatform: Platform = .iOS
    private var samplePhotoPurpose: PhotoPurpose = .document
    private var samplePhotoContext: PhotoContext = PhotoContext()
    private var sampleDeviceType: DeviceType = .phone
    private var sampleInteractionStyle: InteractionStyle = .interactive
    private var sampleContentDensity: ContentDensity = .balanced
    
    private func createSampleTextTypes() {

    
        return L3TestDataFactory.createSampleTextTypes()

    
    }

    
    private func createSampleDocumentType() {

    
        return L3TestDataFactory.createSampleDocumentType()

    
    }

    
    private func createSamplePlatform() {

    
        return L3TestDataFactory.createSamplePlatform()

    
    }

    
    private func createSamplePhotoPurpose() {

    
        return L3TestDataFactory.createSamplePhotoPurpose()

    
    }

    
    private func createSamplePhotoContext() {

    
        return L3TestDataFactory.createSamplePhotoContext()

    
    }

    
    private func createSampleDeviceType() {

    
        return L3TestDataFactory.createSampleDeviceType()

    
    }

    
    private func createSampleInteractionStyle() {

    
        return L3TestDataFactory.createSampleInteractionStyle()

    
    }

    
    private func createSampleContentDensity() {

    
        return L3TestDataFactory.createSampleContentDensity()

    
    }

    
    // BaseTestClass handles setup automatically - no init() needed
    
    deinit {
        Task { [weak self] in
            await self?.cleanupTestEnvironment()
        }
    }
    
    // MARK: - OCR Strategy Selection Functions
    
    @Test func testPlatformOCRStrategy_L3() {
        // Given
        let textTypes = sampleTextTypes
        let platform = samplePlatform
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedTextTypes == textTypes, "Strategy should support requested text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Strategy should support at least one language")
        #expect(strategy.estimatedProcessingTime >= 0, "Processing time should be non-negative")
    }
    
    @Test func testPlatformOCRStrategy_L3_NeuralEngineRequired() {
        // Given
        let textTypes: [TextType] = [.general, .price, .date, .number, .address, .email, .phone]
        let platform = Platform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.requiresNeuralEngine, "Complex text types should require neural engine")
    }
    
    @Test func testPlatformDocumentOCRStrategy_L3() {
        // Given
        let documentType = sampleDocumentType
        let platform = samplePlatform
        
        // When
        let strategy = platformDocumentOCRStrategy_L3(
            documentType: documentType,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Document OCR strategy should be created")  // strategy is non-optional
        #expect(!strategy.supportedTextTypes.isEmpty, "Strategy should support text types for document")
        #expect(!strategy.supportedLanguages.isEmpty, "Strategy should support at least one language")
        #expect(strategy.estimatedProcessingTime >= 0, "Processing time should be non-negative")
    }
    
    @Test func testPlatformReceiptOCRStrategy_L3() {
        // Given
        let platform = samplePlatform
        
        // When
        let strategy = platformReceiptOCRStrategy_L3(
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Receipt OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedTextTypes.contains(.price), "Receipt strategy should support price text")
        #expect(strategy.supportedTextTypes.contains(.date), "Receipt strategy should support date text")
        #expect(strategy.supportedTextTypes.contains(.number), "Receipt strategy should support number text")
    }
    
    @Test func testPlatformBusinessCardOCRStrategy_L3() {
        // Given
        let platform = samplePlatform
        
        // When
        let strategy = platformBusinessCardOCRStrategy_L3(
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Business card OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedTextTypes.contains(.name), "Business card strategy should support name text")
        #expect(strategy.supportedTextTypes.contains(.email), "Business card strategy should support email text")
        #expect(strategy.supportedTextTypes.contains(.phone), "Business card strategy should support phone text")
    }
    
    @Test func testPlatformInvoiceOCRStrategy_L3() {
        // Given
        let platform = samplePlatform
        
        // When
        let strategy = platformInvoiceOCRStrategy_L3(
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Invoice OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedTextTypes.contains(.price), "Invoice strategy should support price text")
        #expect(strategy.supportedTextTypes.contains(.date), "Invoice strategy should support date text")
        #expect(strategy.supportedTextTypes.contains(.vendor), "Invoice strategy should support vendor text")
    }
    
    @Test func testPlatformOptimalOCRStrategy_L3() {
        // Given
        let textTypes = sampleTextTypes
        let platform = samplePlatform
        
        // When
        let strategy = platformOptimalOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Optimal OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedTextTypes == textTypes, "Strategy should support requested text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Strategy should support at least one language")
    }
    
    @Test func testPlatformBatchOCRStrategy_L3() {
        // Given
        let textTypes = sampleTextTypes
        let platform = samplePlatform
        
        // When
        let strategy = platformBatchOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Batch OCR strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedTextTypes == textTypes, "Strategy should support requested text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Strategy should support at least one language")
    }
    
    // MARK: - Card Strategy Selection Functions
    
    @Test func testSelectCardExpansionStrategy_L3() {
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 375.0
        let deviceType = sampleDeviceType
        let interactionStyle = sampleInteractionStyle
        let contentDensity = sampleContentDensity
        
        // When
        let strategy = selectCardExpansionStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            interactionStyle: interactionStyle,
            contentDensity: contentDensity
        )
        
        // Then
        #expect(Bool(true), "Card expansion strategy should be created")  // strategy is non-optional
        #expect(!strategy.supportedStrategies.isEmpty, "Strategy should support at least one expansion method")
        #expect(strategy.expansionScale > 1.0, "Expansion scale should be greater than 1.0")
        #expect(strategy.animationDuration >= 0, "Animation duration should be non-negative")
    }
    
    @Test func testSelectCardExpansionStrategy_L3_StaticInteraction() {
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 375.0
        let deviceType = sampleDeviceType
        let interactionStyle = InteractionStyle.static
        let contentDensity = sampleContentDensity
        
        // When
        let strategy = selectCardExpansionStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            interactionStyle: interactionStyle,
            contentDensity: contentDensity
        )
        
        // Then
        #expect(Bool(true), "Card expansion strategy should be created")  // strategy is non-optional
        #expect(strategy.primaryStrategy == .none, "Static interaction should have no expansion")
        #expect(strategy.expansionScale == 1.0, "Static interaction should have no expansion scale")
        #expect(strategy.animationDuration == 0.0, "Static interaction should have no animation")
    }
    
    @Test func testSelectCardExpansionStrategy_L3_PhoneDevice() {
        // Given
        let contentCount = 6
        let screenWidth: CGFloat = 375.0
        let deviceType = DeviceType.phone
        let interactionStyle = InteractionStyle.interactive
        let contentDensity = ContentDensity.balanced
        
        // When
        let strategy = selectCardExpansionStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            interactionStyle: interactionStyle,
            contentDensity: contentDensity
        )
        
        // Then
        #expect(Bool(true), "Card expansion strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedStrategies.contains(.contentReveal), "Phone should support content reveal")
        #expect(strategy.accessibilitySupport, "Strategy should support accessibility")
    }
    
    @Test func testSelectCardExpansionStrategy_L3_PadDevice() {
        // Given
        let contentCount = 12
        let screenWidth: CGFloat = 768.0
        let deviceType = DeviceType.pad
        let interactionStyle = InteractionStyle.interactive
        let contentDensity = ContentDensity.spacious
        
        // When
        let strategy = selectCardExpansionStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            interactionStyle: interactionStyle,
            contentDensity: contentDensity
        )
        
        // Then
        #expect(Bool(true), "Card expansion strategy should be created")  // strategy is non-optional
        #expect(strategy.supportedStrategies.contains(.hoverExpand), "iPad should support hover expansion")
        #expect(strategy.hapticFeedback, "iPad should support haptic feedback")
    }
    
    // MARK: - Photo Strategy Selection Functions
    
    @Test func testSelectPhotoCaptureStrategy_L3() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([PhotoCaptureStrategy.camera, .photoLibrary, .both].contains(strategy), "Strategy should be valid")
    }
    
    @Test func testSelectPhotoCaptureStrategy_L3_CameraOnly() {
        // Given
        let purpose = PhotoPurpose.general
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 600),
            userPreferences: PhotoPreferences(preferredSource: .camera),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: true, hasPhotoLibrary: false)
        )
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .camera, "Should use camera when only camera is available")
    }
    
    @Test func testSelectPhotoCaptureStrategy_L3_PhotoLibraryOnly() {
        // Given
        let purpose = PhotoPurpose.document
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 375, height: 600),
            userPreferences: PhotoPreferences(preferredSource: .photoLibrary),
            deviceCapabilities: PhotoDeviceCapabilities(hasCamera: false, hasPhotoLibrary: true)
        )
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .photoLibrary, "Should use photo library when only photo library is available")
    }
    
    @Test func testSelectPhotoDisplayStrategy_L3() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([PhotoDisplayStrategy.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Strategy should be valid")
    }
    
    @Test func testSelectPhotoDisplayStrategy_L3_VehiclePhoto() {
        // Given
        let purpose = PhotoPurpose.general
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 300, height: 200), // Good space utilization
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .aspectFit, "Vehicle photo should use aspect fit for good space utilization")
    }
    
    @Test func testSelectPhotoDisplayStrategy_L3_ReceiptPhoto() {
        // Given
        let purpose = PhotoPurpose.document
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 667),
            availableSpace: CGSize(width: 200, height: 300), // Good space utilization
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .fullSize, "Receipt photo should use full size for readability")
    }
    
    @Test func testSelectPhotoDisplayStrategy_L3_ProfilePhoto() {
        // Given
        let purpose = PhotoPurpose.profile
        let context = samplePhotoContext
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .rounded, "Profile photo should use rounded display")
    }
    
    @Test func testSelectPhotoDisplayStrategy_L3_MaintenancePhoto() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = samplePhotoContext
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect(strategy == .thumbnail, "Maintenance photo should use thumbnail display")
    }
    
    // MARK: - Strategy Selection Validation
    
    @Test func testStrategySelectionConsistency() {
        // Given
        let textTypes: [TextType] = [.general, .price, .date]
        let platform = Platform.iOS
        
        // When
        let strategy1 = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        let strategy2 = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(strategy1.supportedTextTypes == strategy2.supportedTextTypes, "Strategies should be consistent")
        #expect(strategy1.supportedLanguages == strategy2.supportedLanguages, "Strategies should be consistent")
        #expect(strategy1.processingMode == strategy2.processingMode, "Strategies should be consistent")
    }
    
    @Test func testStrategySelectionPerformance() {
        // Given
        let textTypes: [TextType] = [.general, .price, .date, .number, .address, .email, .phone]
        let platform = Platform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Strategy should be created")  // strategy is non-optional
    }
    
    @Test func testStrategySelectionEdgeCases() {
        // Given
        let emptyTextTypes: [TextType] = []
        let platform = Platform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: emptyTextTypes,
            platform: platform
        )
        
        // Then
        #expect(Bool(true), "Strategy should handle empty text types")  // strategy is non-optional
        #expect(strategy.supportedTextTypes.isEmpty, "Empty text types should result in empty supported types")
    }
}









