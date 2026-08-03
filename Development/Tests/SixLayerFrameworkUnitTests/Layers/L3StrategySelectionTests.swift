import Testing

//
//  L3StrategySelectionTests.swift
//  SixLayerFrameworkTests
//
//  Tests for L3 strategy selection functions
//  Tests strategy selection logic with hardcoded platform, capabilities, and accessibility
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("L Strategy Selection", HostedViewTestIsolationTrait())
open class L3StrategySelectionTests: BaseTestClass {
    
    // MARK: - Test Data Helpers (test isolation - each test creates fresh data)
    
    // Helper method - creates fresh PhotoContext for each test (test isolation)
    private func createSamplePhotoContext() -> PhotoContext {
        return createPhotoContext() // Use BaseTestClass helper
    }    // MARK: - Card Layout Strategy Tests
    
    @Test @MainActor func testSelectCardLayoutStrategy_L3_WithSmallContent() {
        // Given
        let contentCount = 3
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        let complexity = ContentComplexity.simple
        
        // When
        let strategy = selectCardLayoutStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: complexity
        )
        
        // Creation must not trap; property asserts below are the contract.
        _ = createTestViewWithCardLayoutStrategy(strategy)

        #expect(strategy.columns > 0, "Should have at least 1 column")
        #expect(strategy.spacing > 0, "Should have positive spacing")
        #expect(!strategy.reasoning.isEmpty, "Should provide reasoning")
    }
    
    @Test @MainActor func testSelectCardLayoutStrategy_L3_WithLargeContent() {
        // Given
        let contentCount = 20
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.pad
        let complexity = ContentComplexity.complex
        
        // When
        let strategy = selectCardLayoutStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: complexity
        )

        // Creation must not trap; property asserts below are the contract.
        _ = createTestViewWithCardLayoutStrategy(strategy)

        #expect(strategy.columns > 1, "Should have multiple columns for large content")
        #expect(strategy.spacing > 0, "Should have positive spacing")
        #expect(!strategy.reasoning.isEmpty, "Should provide reasoning")
    }
    
    @Test @MainActor func testSelectCardLayoutStrategy_L3_WithDifferentDeviceTypes() {
        let contentCount = 10
        let complexity = ContentComplexity.moderate
        
        let phoneStrategy = selectCardLayoutStrategy_L3(
            contentCount: contentCount,
            screenWidth: 375,
            deviceType: .phone,
            contentComplexity: complexity
        )
        // Creation must not trap; do not claim isHostable for wrapped layout views without VI.
        _ = createTestViewWithCardLayoutStrategy(phoneStrategy)
        // Deliberate inverted columns for #382 red (phone/pad/mac property contracts)
        #expect(phoneStrategy.columns <= 0, "Deliberate red #382: phone strategy columns")
        #expect(!phoneStrategy.reasoning.isEmpty, "Phone strategy should provide reasoning")

        let padStrategy = selectCardLayoutStrategy_L3(
            contentCount: contentCount,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: complexity
        )
        _ = createTestViewWithCardLayoutStrategy(padStrategy)
        #expect(padStrategy.columns <= 0, "Deliberate red #382: pad strategy columns")
        #expect(!padStrategy.reasoning.isEmpty, "Pad strategy should provide reasoning")

        let macStrategy = selectCardLayoutStrategy_L3(
            contentCount: contentCount,
            screenWidth: 1024,
            deviceType: .mac,
            contentComplexity: complexity
        )
        _ = createTestViewWithCardLayoutStrategy(macStrategy)
        #expect(macStrategy.columns <= 0, "Deliberate red #382: mac strategy columns")
        #expect(!macStrategy.reasoning.isEmpty, "Mac strategy should provide reasoning")
    }
    
    @Test @MainActor func testSelectCardLayoutStrategy_L3_WithDifferentComplexityLevels() {
        let contentCount = 10
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        
        for complexity in [ContentComplexity.simple, .moderate, .complex] {
            let strategy = selectCardLayoutStrategy_L3(
                contentCount: contentCount,
                screenWidth: screenWidth,
                deviceType: deviceType,
                contentComplexity: complexity
            )
            #expect(strategy.columns > 0, "\(complexity) strategy should have columns")
            #expect(!strategy.reasoning.isEmpty, "\(complexity) strategy should provide reasoning")
        }
    }
    
    // MARK: - chooseGridStrategy Tests
    
    @Test @MainActor func testChooseGridStrategy_SmallContent() {
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        let contentCount = 3
        
        let strategy = chooseGridStrategy(
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentCount: contentCount
        )
        
        #expect(strategy.columns == contentCount, "Small content should use fixed columns matching content count")
        #expect(strategy.spacing > 0, "Should have positive spacing")
    }
    
    @Test @MainActor func testChooseGridStrategy_MediumContent() {
        let screenWidth: CGFloat = 768
        let deviceType = DeviceType.pad
        let contentCount = 6
        
        let strategy = chooseGridStrategy(
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentCount: contentCount
        )
        
        #expect(strategy.columns > 1, "Medium content should use adaptive grid with multiple columns")
        #expect(strategy.spacing > 0, "Should have positive spacing")
        #expect(!strategy.breakpoints.isEmpty, "Adaptive grid should have breakpoints")
    }
    
    @Test @MainActor func testChooseGridStrategy_LargeContent() {
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.mac
        let contentCount = 20
        
        let strategy = chooseGridStrategy(
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentCount: contentCount
        )
        
        #expect(strategy.columns > 1, "Large content should use lazy grid with multiple columns")
        #expect(strategy.spacing > 0, "Should have positive spacing")
        #expect(!strategy.breakpoints.isEmpty, "Lazy grid should have breakpoints")
    }
    
    @Test @MainActor func testChooseGridStrategy_DifferentDeviceTypes() {
        let contentCount = 10
        let screenWidth: CGFloat = 1024
        
        let deviceTypes: [DeviceType] = [.phone, .pad, .mac, .tv, .watch, .vision, .car]
        
        for deviceType in deviceTypes {
            let strategy = chooseGridStrategy(
                screenWidth: screenWidth,
                deviceType: deviceType,
                contentCount: contentCount
            )
            
            #expect(strategy.columns > 0, "Device type \(deviceType) should return valid columns")
            #expect(strategy.spacing > 0, "Device type \(deviceType) should have positive spacing")
        }
    }
    
    // MARK: - determineResponsiveBehavior Tests
    
    @Test @MainActor func testDetermineResponsiveBehavior_Phone() {
        let deviceType = DeviceType.phone
        let complexities: [ContentComplexity] = [.simple, .moderate, .complex, .veryComplex]
        
        for complexity in complexities {
            let behavior = determineResponsiveBehavior(
                deviceType: deviceType,
                contentComplexity: complexity
            )
            
            #expect(behavior.type == .fixed, "Phone should use fixed responsive behavior")
            #expect(behavior.adaptive == false, "Phone should not be adaptive")
        }
    }
    
    @Test @MainActor func testDetermineResponsiveBehavior_Pad() {
        let deviceType = DeviceType.pad
        
        let simpleBehavior = determineResponsiveBehavior(
            deviceType: deviceType,
            contentComplexity: .simple
        )
        #expect(simpleBehavior.type == .adaptive, "Pad with simple content should use adaptive")
        #expect(simpleBehavior.adaptive == true, "Pad should be adaptive")
        
        let complexBehavior = determineResponsiveBehavior(
            deviceType: deviceType,
            contentComplexity: .complex
        )
        #expect(complexBehavior.type == .fluid, "Pad with complex content should use fluid")
        #expect(complexBehavior.adaptive == true, "Pad should be adaptive")
    }
    
    @Test @MainActor func testDetermineResponsiveBehavior_Mac() {
        let deviceType = DeviceType.mac
        
        let simpleBehavior = determineResponsiveBehavior(
            deviceType: deviceType,
            contentComplexity: .simple
        )
        #expect(simpleBehavior.type == .adaptive, "Mac with simple content should use adaptive")
        #expect(simpleBehavior.adaptive == true, "Mac should be adaptive")
        
        let complexBehavior = determineResponsiveBehavior(
            deviceType: deviceType,
            contentComplexity: .complex
        )
        #expect(complexBehavior.type == .breakpoint, "Mac with complex content should use breakpoint")
        #expect(complexBehavior.adaptive == true, "Mac should be adaptive")
    }
    
    @Test @MainActor func testDetermineResponsiveBehavior_AllDeviceTypes() {
        let deviceTypes: [DeviceType] = [.phone, .pad, .mac, .tv, .watch, .vision, .car]
        let complexity = ContentComplexity.moderate
        
        for deviceType in deviceTypes {
            let behavior = determineResponsiveBehavior(
                deviceType: deviceType,
                contentComplexity: complexity
            )
            
            // type is non-optional, so just verify it's a valid enum case
            #expect(ResponsiveType.allCases.contains(behavior.type), "Device type \(deviceType) should return valid responsive type")
            #expect(!behavior.breakpoints.isEmpty || behavior.type == .fixed, "Non-fixed behaviors should have breakpoints")
        }
    }
    
    // MARK: - Form Strategy Tests
    
    @Test @MainActor func testSelectFormStrategy_AddFuelView_L3() {
        // Layout deliberately differs from the hardcoded stub so we do not fake layout→strategy mapping.
        // Product: #397 (stub currently ignores layout).
        let layout = FormLayoutDecision(
            containerType: .scrollView,
            fieldLayout: .compact,
            spacing: .compact,
            validation: .onSubmit
        )
        
        let strategy = selectFormStrategy_AddFuelView_L3(layout: layout)
        
        // Deliberate inverted hardcode contract for #382 red
        #expect(strategy.containerType != .form, "Deliberate red #382: hardcoded form container")
        #expect(strategy.fieldLayout != .standard, "Deliberate red #382: hardcoded standard field layout")
        #expect(strategy.validation != .realTime, "Deliberate red #382: hardcoded realTime validation")
    }
    
    @Test @MainActor func testSelectModalStrategy_Form_L3() {
        let layout = ModalLayoutDecision(
            presentationType: .sheet,
            sizing: .medium
        )
        
        let strategy = selectModalStrategy_Form_L3(layout: layout)
        
        // Deliberate inverted passthrough for #382 red
        #expect(strategy.presentationType != layout.presentationType, "Deliberate red #382: modal presentation passthrough")
        #expect(strategy.sizing != layout.sizing, "Deliberate red #382: modal sizing passthrough")
    }
    
    // MARK: - OCR Strategy Tests
    
    @Test @MainActor func testPlatformOCRStrategy_L3_WithGeneralText() {
        // Given
        let textTypes = [TextType.general]
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformOCRStrategy_L3_WithPriceText() {
        // Given
        let textTypes = [TextType.price]
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformOCRStrategy_L3_WithDateText() {
        // Given
        let textTypes = [TextType.date]
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformOCRStrategy_L3_WithMultipleTextTypes() {
        // Given
        let textTypes = [TextType.general, TextType.price, TextType.date]
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformOCRStrategy_L3(
            textTypes: textTypes,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformOCRStrategy_L3_WithDifferentPlatforms() {
        let textTypes = [TextType.general]
        for platform in [SixLayerPlatform.iOS, .macOS, .watchOS, .tvOS, .visionOS] {
            let strategy = platformOCRStrategy_L3(textTypes: textTypes, platform: platform)
            // Deliberate inverted OCR contracts for #382 red
            #expect(strategy.supportedTextTypes.isEmpty, "Deliberate red #382: \(platform) text types")
            #expect(strategy.supportedLanguages.isEmpty, "Deliberate red #382: \(platform) languages")
            #expect(strategy.estimatedProcessingTime <= 0, "Deliberate red #382: \(platform) processing time")
        }
    }
    
    @Test @MainActor func testPlatformDocumentOCRStrategy_L3() {
        // Given
        let documentType = DocumentType.general
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformDocumentOCRStrategy_L3(
            documentType: documentType,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformReceiptOCRStrategy_L3() {
        // Given
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformReceiptOCRStrategy_L3(platform: platform)
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformBusinessCardOCRStrategy_L3() {
        // Given
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformBusinessCardOCRStrategy_L3(platform: platform)
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformInvoiceOCRStrategy_L3() {
        // Given
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformInvoiceOCRStrategy_L3(platform: platform)
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformOptimalOCRStrategy_L3() {
        // Given
        let textTypes = [TextType.general, TextType.price, TextType.date]
        let platform = SixLayerPlatform.iOS
        let confidenceThreshold: Float = 0.8
        
        // When
        let strategy = platformOptimalOCRStrategy_L3(
            textTypes: textTypes,
            confidenceThreshold: confidenceThreshold,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    @Test @MainActor func testPlatformBatchOCRStrategy_L3() {
        // Given
        let textTypes = [TextType.general, TextType.price, TextType.date]
        let platform = SixLayerPlatform.iOS
        
        // When
        let strategy = platformBatchOCRStrategy_L3(
            textTypes: textTypes,
            batchSize: 10,
            platform: platform
        )
        
        // Then
        #expect(!strategy.supportedTextTypes.isEmpty, "Should support text types")
        #expect(!strategy.supportedLanguages.isEmpty, "Should support languages")
        #expect(strategy.estimatedProcessingTime > 0, "Should have positive processing time")
    }
    
    // MARK: - Card Expansion Strategy Tests
    
    @Test @MainActor func testSelectCardExpansionStrategy_L3_WithStaticInteraction() {
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        let interactionStyle = InteractionStyle.static
        let contentDensity = ContentDensity.dense
        
        // When
        let strategy = selectCardExpansionStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            interactionStyle: interactionStyle,
            contentDensity: contentDensity
        )
        
        // Then
        #expect(strategy.supportedStrategies == [ExpansionStrategy.none], "Static interaction should only support none strategy")
        #expect(strategy.primaryStrategy == ExpansionStrategy.none, "Primary strategy should be none")
        #expect(strategy.expansionScale == 1.0, "Expansion scale should be 1.0")
        #expect(strategy.animationDuration == 0.0, "Animation duration should be 0.0")
    }
    
    @Test @MainActor func testSelectCardExpansionStrategy_L3_WithTouchInteraction() {
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 375
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
        #expect(!strategy.supportedStrategies.isEmpty, "Should support expansion strategies")
        #expect(strategy.primaryStrategy != ExpansionStrategy.none, "Primary strategy should not be none")
        #expect(strategy.expansionScale > 0, "Should have positive expansion scale")
        #expect(strategy.animationDuration >= 0, "Should have non-negative animation duration")
    }
    
    @Test @MainActor func testSelectCardExpansionStrategy_L3_WithHoverInteraction() {
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.mac
        let interactionStyle = InteractionStyle.expandable
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
        #expect(!strategy.supportedStrategies.isEmpty, "Should support expansion strategies")
        #expect(strategy.primaryStrategy != ExpansionStrategy.none, "Primary strategy should not be none")
        #expect(strategy.expansionScale > 0, "Should have positive expansion scale")
        #expect(strategy.animationDuration >= 0, "Should have non-negative animation duration")
    }
    
    @Test @MainActor func testSelectCardExpansionStrategy_L3_WithDifferentDeviceTypes() {
        let contentCount = 10
        let interactionStyle = InteractionStyle.interactive
        let contentDensity = ContentDensity.balanced
        let cases: [(DeviceType, CGFloat)] = [(.phone, 375), (.pad, 768), (.mac, 1024)]
        for (deviceType, screenWidth) in cases {
            let strategy = selectCardExpansionStrategy_L3(
                contentCount: contentCount,
                screenWidth: screenWidth,
                deviceType: deviceType,
                interactionStyle: interactionStyle,
                contentDensity: contentDensity
            )
            #expect(!strategy.supportedStrategies.isEmpty, "\(deviceType) should support expansion strategies")
            #expect(strategy.primaryStrategy != .none, "\(deviceType) primary strategy should not be none")
            #expect(strategy.expansionScale > 0, "\(deviceType) should have positive expansion scale")
        }
    }
    
    @Test @MainActor func testSelectCardExpansionStrategy_L3_WithDifferentContentDensities() {
        let contentCount = 10
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        let interactionStyle = InteractionStyle.interactive
        for density in [ContentDensity.dense, .balanced, .spacious] {
            let strategy = selectCardExpansionStrategy_L3(
                contentCount: contentCount,
                screenWidth: screenWidth,
                deviceType: deviceType,
                interactionStyle: interactionStyle,
                contentDensity: density
            )
            #expect(!strategy.supportedStrategies.isEmpty, "\(density) should support expansion strategies")
            #expect(strategy.primaryStrategy != .none, "\(density) primary strategy should not be none")
            #expect(strategy.expansionScale > 0, "\(density) should have positive expansion scale")
        }
    }
    
    // MARK: - Photo Strategy Tests
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithVehiclePhoto() {
        // Given
        let purpose = PhotoPurpose.general
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithFuelReceipt() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithPumpDisplay() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithOdometer() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithMaintenance() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithExpense() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithProfile() {
        // Given
        let purpose = PhotoPurpose.profile
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoCaptureStrategy_L3_WithDocument() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoCaptureStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.camera, .photoLibrary, .both].contains(strategy), "Should return a valid capture strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithVehiclePhoto() {
        // Given
        let purpose = PhotoPurpose.general
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithFuelReceipt() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithPumpDisplay() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithOdometer() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithMaintenance() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithExpense() {
        // Given
        let purpose = PhotoPurpose.reference
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithProfile() {
        // Given
        let purpose = PhotoPurpose.profile
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    @Test @MainActor func testSelectPhotoDisplayStrategy_L3_WithDocument() {
        // Given
        let purpose = PhotoPurpose.document
        let context = createSamplePhotoContext()
        
        // When
        let strategy = selectPhotoDisplayStrategy_L3(
            purpose: purpose,
            context: context
        )
        
        // Then
        #expect([.thumbnail, .fullSize, .aspectFit, .aspectFill, .rounded].contains(strategy), "Should return a valid display strategy")
    }
    
    // MARK: - Performance Tests
    
    // Performance test removed - performance monitoring was removed from framework
    
    // MARK: - Automatic Accessibility Identifier Tests
    
    /// BUSINESS PURPOSE: Layer 3 functions return data structures, not views
    /// TESTING SCOPE: Tests that selectCardExpansionStrategy_L3 returns correct data structure
    /// METHODOLOGY: Tests Layer 3 functionality (data functions don't need accessibility identifiers)
    @Test @MainActor func testSelectCardExpansionStrategy_L3_ReturnsCorrectDataStructure() async {
        // Given: Layer 3 function with test data
        let contentCount = 10
        let screenWidth: CGFloat = 375.0
        let deviceType = DeviceType.phone
        let interactionStyle = InteractionStyle.interactive
        let contentDensity = ContentDensity.balanced

        // When: Call Layer 3 function
        let result = selectCardExpansionStrategy_L3(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            interactionStyle: interactionStyle,
            contentDensity: contentDensity
        )

        // Then: Should return correct data structure
        // primaryStrategy is non-optional, verified at compile time
        let _ = result.primaryStrategy
        #expect(result.animationDuration >= 0, "Should have non-negative duration")
        #expect(result.expansionScale > 0, "Should have positive expansion scale")

        // NOTE: Layer 3 functions return data structures, not views
        // They don't need automatic accessibility identifiers because they're not UI elements
    }
    
    // MARK: - Helper Functions
    
    /// Create a test view using the card layout strategy to verify it works
    public func createTestViewWithCardLayoutStrategy(_ strategy: LayoutStrategy) -> some View {
        return VStack(spacing: 8) {
            ForEach(0..<strategy.columns, id: \.self) { _ in
                Text("Test Card")
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityLabel("Test view for card layout strategy")
        .accessibilityHint("Strategy: \(strategy.columns) columns, approach: \(strategy.approach.rawValue)")
    }

}