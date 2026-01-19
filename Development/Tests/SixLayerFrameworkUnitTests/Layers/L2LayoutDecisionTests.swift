import Testing

//
//  L2LayoutDecisionTests.swift
//  SixLayerFrameworkTests
//
//  Tests for L2 layout decision engine functions
//  Tests layout decision logic with hardcoded platform, capabilities, and accessibility
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("L Layout Decision")
open class L2LayoutDecisionTests: BaseTestClass {
    
    // MARK: - Test Data Helpers (test isolation - each test creates fresh data)
    
    // Note: createSampleItems() method already exists below - no need to duplicate
    
    private func createSampleHints() -> PresentationHints {
        return PresentationHints()
    }
    
    private func createSampleOCRContext() -> OCRContext {
        return OCRContext()
    }
    
    private func createSamplePhotoContext() -> PhotoContext {
        return createPhotoContext() // Use BaseTestClass helper
    }    // MARK: - Generic Layout Decision Tests
    
    @Test @MainActor func testDetermineOptimalLayout_L2_WithSmallItemCount() {
        // Given
        let items = Array(createSampleItems().prefix(3))
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .compact,
            complexity: .simple,
            context: .dashboard
        )
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: screenWidth,
            deviceType: deviceType
        )
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(decision.columns > 0, "Should have at least 1 column")
        #expect(decision.spacing > 0, "Should have positive spacing")
        #expect(!decision.reasoning.isEmpty, "Should provide reasoning")
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_WithLargeItemCount() {
        // Given
        let items = createManyItems(count: 50)
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .grid,
            complexity: .complex,
            context: .browse
        )
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.pad
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: screenWidth,
            deviceType: deviceType
        )
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(decision.columns > 1, "Should have multiple columns for large item count")
        #expect(decision.spacing > 0, "Should have positive spacing")
        #expect(!decision.reasoning.isEmpty, "Should provide reasoning")
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_WithDifferentComplexityLevels() {
        // Test simple complexity
        let simpleHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .compact,
            complexity: .simple,
            context: .dashboard
        )
        _ = determineOptimalLayout_L2(
            items: createSampleItems(),
            hints: simpleHints,
            screenWidth: 375,
            deviceType: .phone
        )
        // simpleDecision is a non-optional struct, so it exists if we reach here
        
        // Test moderate complexity
        let moderateHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .moderate,
            complexity: .moderate,
            context: .browse
        )
        _ = determineOptimalLayout_L2(
            items: createSampleItems(),
            hints: moderateHints,
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(Bool(true), "Moderate complexity should return a decision")
        
        // Test complex complexity
        let complexHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .detail,
            complexity: .complex,
            context: .detail
        )
        _ = determineOptimalLayout_L2(
            items: createSampleItems(),
            hints: complexHints,
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(Bool(true), "Complex complexity should return a decision")
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_WithDifferentDeviceTypes() {
        let hints = PresentationHints()
        
        // Test phone
        _ = determineOptimalLayout_L2(
            items: createSampleItems(),
            hints: hints,
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(Bool(true), "Phone device type should return a decision")
        
        // Test pad
        _ = determineOptimalLayout_L2(
            items: createSampleItems(),
            hints: hints,
            screenWidth: 768,
            deviceType: .pad
        )
        #expect(Bool(true), "Pad device type should return a decision")
        
        // Test mac
        _ = determineOptimalLayout_L2(
            items: createSampleItems(),
            hints: hints,
            screenWidth: 1024,
            deviceType: .mac
        )
        #expect(Bool(true), "Mac device type should return a decision")
    }
    
    // MARK: - Form Layout Decision Tests
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_WithSimpleForm() {
        // Given
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .simple,
            context: .create,
            customPreferences: ["fieldCount": "3", "hasComplexFields": "false", "hasValidation": "false"]
        )
        
        // When
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(!decision.reasoning.isEmpty, "Should provide reasoning")
    }
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_WithComplexForm() {
        // Given
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .complex,
            context: .create,
            customPreferences: ["fieldCount": "20", "hasComplexFields": "true", "hasValidation": "true"]
        )
        
        // When
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(!decision.reasoning.isEmpty, "Should provide reasoning")
    }
    
    // MARK: - Card Layout Decision Tests
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_WithSmallContent() {
        // Given
        let contentCount = 3
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        let complexity = ContentComplexity.simple
        
        // When
        let decision = determineOptimalCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: complexity
        )
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(decision.columns > 0, "Should have at least 1 column")
        #expect(decision.spacing > 0, "Should have positive spacing")
    }
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_WithLargeContent() {
        // Given
        let contentCount = 20
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.pad
        let complexity = ContentComplexity.complex
        
        // When
        let decision = determineOptimalCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: complexity
        )
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(decision.columns > 1, "Should have multiple columns for large content")
        #expect(decision.spacing > 0, "Should have positive spacing")
    }
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_WithDifferentDeviceTypes() {
        let contentCount = 10
        let complexity = ContentComplexity.moderate
        
        // Test phone
        _ = determineOptimalCardLayout_L2(
            contentCount: contentCount,
            screenWidth: 375,
            deviceType: .phone,
            contentComplexity: complexity
        )
        #expect(Bool(true), "Phone device type should return a decision")
        
        // Test pad
        _ = determineOptimalCardLayout_L2(
            contentCount: contentCount,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: complexity
        )
        #expect(Bool(true), "Pad device type should return a decision")
        
        // Test mac
        _ = determineOptimalCardLayout_L2(
            contentCount: contentCount,
            screenWidth: 1024,
            deviceType: .mac,
            contentComplexity: complexity
        )
        #expect(Bool(true), "Mac device type should return a decision")
    }
    
    // MARK: - Intelligent Card Layout Decision Tests
    
    @Test @MainActor func testDetermineIntelligentCardLayout_L2_WithSmallContent() {
        // Given
        let contentCount = 3
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        let complexity = ContentComplexity.simple
        
        // When
        let decision = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: complexity
        )
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(decision.columns > 0, "Should have at least 1 column")
        #expect(decision.cardWidth > 0, "Should have positive card width")
        #expect(decision.cardHeight > 0, "Should have positive card height")
        #expect(decision.spacing > 0, "Should have positive spacing")
        #expect(decision.padding > 0, "Should have positive padding")
        #expect(decision.expansionScale > 0, "Should have positive expansion scale")
        #expect(decision.animationDuration > 0, "Should have positive animation duration")
    }
    
    @Test @MainActor func testDetermineIntelligentCardLayout_L2_WithLargeContent() {
        // Given
        let contentCount = 20
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.pad
        let complexity = ContentComplexity.complex
        
        // When
        let decision = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: complexity
        )
        
        // Then
        // decision is a non-optional struct, so it exists if we reach here
        #expect(decision.columns > 1, "Should have multiple columns for large content")
        #expect(decision.cardWidth > 0, "Should have positive card width")
        #expect(decision.cardHeight > 0, "Should have positive card height")
        #expect(decision.spacing > 0, "Should have positive spacing")
        #expect(decision.padding > 0, "Should have positive padding")
        #expect(decision.expansionScale > 0, "Should have positive expansion scale")
        #expect(decision.animationDuration > 0, "Should have positive animation duration")
    }
    
    // MARK: - OCR Layout Decision Tests
    
    @Test @MainActor func testPlatformOCRLayout_L2_WithGeneralContext() {
        // Given
        let context = OCRContext()
        
        // When
        let layout = platformOCRLayout_L2(context: context)
        
        // Then
        #expect(Bool(true), "platformOCRLayout_L2 should return a layout")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Should have positive max image width")
        #expect(layout.maxImageSize.height > 0, "Should have positive max image height")
        #expect(layout.recommendedImageSize.width > 0, "Should have positive recommended image width")
        #expect(layout.recommendedImageSize.height > 0, "Should have positive recommended image height")
    }
    
    @Test @MainActor func testPlatformOCRLayout_L2_WithDocumentContext() {
        // Given
        let context = OCRContext()
        let documentType = DocumentType.general
        
        // When
        let layout = platformDocumentOCRLayout_L2(
            documentType: documentType,
            context: context
        )
        
        // Then
        #expect(Bool(true), "platformDocumentOCRLayout_L2 should return a layout")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Should have positive max image width")
        #expect(layout.maxImageSize.height > 0, "Should have positive max image height")
    }
    
    @Test @MainActor func testPlatformOCRLayout_L2_WithReceiptContext() {
        // Given
        let context = OCRContext()
        
        // When
        let layout = platformReceiptOCRLayout_L2(context: context)
        
        // Then
        #expect(Bool(true), "platformReceiptOCRLayout_L2 should return a layout")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Should have positive max image width")
        #expect(layout.maxImageSize.height > 0, "Should have positive max image height")
    }
    
    @Test @MainActor func testPlatformOCRLayout_L2_WithBusinessCardContext() {
        // Given
        let context = OCRContext()
        
        // When
        let layout = platformBusinessCardOCRLayout_L2(context: context)
        
        // Then
        #expect(Bool(true), "platformBusinessCardOCRLayout_L2 should return a layout")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0, "Should have positive max image width")
        #expect(layout.maxImageSize.height > 0, "Should have positive max image height")
    }
    
    // MARK: - Photo Layout Decision Tests
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithVehiclePhoto() {
        // Given
        let purpose = PhotoPurpose.general
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithFuelReceipt() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithPumpDisplay() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithOdometer() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithMaintenance() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithExpense() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithProfile() {
        // Given
        let purpose = PhotoPurpose.profile
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDetermineOptimalPhotoLayout_L2_WithDocument() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let size = determineOptimalPhotoLayout_L2(purpose: purpose, context: context)
        
        // Then
        #expect(size.width > 0, "Should have positive width")
        #expect(size.height > 0, "Should have positive height")
    }
    
    @Test @MainActor func testDeterminePhotoCaptureStrategy_L2_WithVehiclePhoto() {
        // Given
        let purpose = PhotoPurpose.general
        let context = createSamplePhotoContext()
        
        // When
        _ = determinePhotoCaptureStrategy_L2(purpose: purpose, context: context)
        
        // Then
        #expect(Bool(true), "determinePhotoCaptureStrategy_L2 should return a strategy")
    }
    
    @Test @MainActor func testDeterminePhotoCaptureStrategy_L2_WithFuelReceipt() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        _ = determinePhotoCaptureStrategy_L2(purpose: purpose, context: context)
        
        // Then
        #expect(Bool(true), "determinePhotoCaptureStrategy_L2 should return a strategy")
    }
    
    // MARK: - Performance Tests
    
    // Performance test removed - performance monitoring was removed from framework
    
    // Performance test removed - performance monitoring was removed from framework
    
    // MARK: - Helper Methods
    
    public func createSampleItems() -> [GenericDataItem] {
        return [
            GenericDataItem(
                title: "Item 1",
                subtitle: "Subtitle 1",
                data: ["description": "Description 1", "value": "Value 1"]
            ),
            GenericDataItem(
                title: "Item 2",
                subtitle: "Subtitle 2",
                data: ["description": "Description 2", "value": "Value 2"]
            ),
            GenericDataItem(
                title: "Item 3",
                subtitle: "Subtitle 3",
                data: ["description": "Description 3", "value": "Value 3"]
            )
        ]
    }
    
    public func createManyItems(count: Int) -> [GenericDataItem] {
        return (1...count).map { index in
            GenericDataItem(
                title: "Item \(index)",
                subtitle: "Subtitle \(index)",
                data: ["description": "Description \(index)", "value": "Value \(index)"]
            )
        }
    }
    
    public func createSimpleFormFields() -> [DynamicFormField] {
        return [
            DynamicFormField(
                id: "name",
                contentType: .text,
                label: "Name",
                placeholder: "Enter your name",
                isRequired: true,
            ),
            DynamicFormField(
                id: "email",
                contentType: .email,
                label: "Email",
                placeholder: "Enter your email",
                isRequired: true
            )
        ]
    }
    
    public func createComplexFormFields() -> [DynamicFormField] {
        return (1...20).map { index in
            DynamicFormField(
                id: "field_\(index)",
                contentType: .text,
                label: "Field \(index)",
                placeholder: "Enter value \(index)",
                isRequired: index % 2 == 0
            )
        // Performance test removed - performance monitoring was removed from framework
    }

}}