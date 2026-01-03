import Testing


//
//  GenericLayoutDecisionTests.swift
//  SixLayerFrameworkTests
//
//  Tests for Generic Layout Decision Functions (Layer 2)
//  Tests the intelligent layout decision engine that analyzes content
//  and makes optimal layout decisions based on content characteristics
//
//  Test Documentation:
//  Business purpose of function: Analyze content characteristics and determine optimal layout approach (uniform, adaptive, responsive, dynamic) and column count
//  What are we actually testing:
//    - Layout approach selection based on item count (small=uniform, medium=adaptive, large=responsive, veryLarge=dynamic)
//    - Column count calculation based on item count, screen width, and device type
//    - Device-specific layout behavior (phone vs pad differences)
//    - Screen width impact on layout decisions
//    - Edge cases (empty items, very large item counts)
//  HOW are we testing it:
//    - Test with different item counts (0, 3, 8, 50, 200) to validate complexity thresholds
//    - Test with different device types (phone, pad) and screen widths
//    - Validate specific layout approach selections (.uniform, .adaptive, .dynamic)
//    - Validate column count calculations with XCTAssertGreaterThan assertions
//    - Test edge cases like empty item arrays
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Generic Layout Decision")
open class GenericLayoutDecisionTests: BaseTestClass {
    
    // MARK: - Test Data
    
    public func createTestItems(count: Int) -> [TestPatterns.TestItem] {
        return (0..<count).map { index in
            TestPatterns.TestItem(
                id: "\(index + 1)",
                title: "Item \(index + 1)"
            )
        }
    }
    
    public func createBasicHints() -> PresentationHints {
        return PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .browse,
            customPreferences: [:]
        )
    }
    
    public func createComplexHints() -> PresentationHints {
        return PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .complex,
            context: .browse,
            customPreferences: [
                "maxColumns": "4",
                "minSpacing": "16.0",
                "performanceMode": "high"
            ]
        )
    }
    
    // MARK: - determineOptimalLayout_L2 Tests
    
    @Test @MainActor func testDetermineOptimalLayout_L2_EmptyItems() {
        initializeTestConfig()
        // Given
        let items: [TestPatterns.TestItem] = []
        let hints = createBasicHints()
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 375,
            deviceType: .phone
        )
        
        // Then
        #expect(decision.columns == 1)
        #expect(decision.approach == LayoutApproach.uniform)
        // Note: Actual implementation returns .uniform for empty items
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_SmallItemCount() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 3)
        let hints = createBasicHints()
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 375,
            deviceType: .phone
        )
        
        // Then
        #expect(decision.columns == 1)
        #expect(decision.approach == LayoutApproach.uniform)
        // Note: Actual implementation returns .uniform for small item counts
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_MediumItemCount() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 8)
        let hints = createBasicHints()
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 768,
            deviceType: .pad
        )
        
        // Then
        #expect(decision.columns > 1)
        #expect(decision.approach == LayoutApproach.adaptive)
        // CardLayoutDecision doesn't have reasoning property
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_LargeItemCount() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 50)
        let hints = createBasicHints()
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1024,
            deviceType: .pad
        )
        
        // Then
        #expect(decision.columns > 2)
        #expect(decision.approach == LayoutApproach.dynamic)
        // CardLayoutDecision doesn't have performance or reasoning properties
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_VeryLargeItemCount() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 200)
        let hints = createBasicHints()
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1024,
            deviceType: .pad
        )
        
        // Then
        #expect(decision.columns >= 3) // Actual device type determines columns
        #expect(decision.approach == LayoutApproach.dynamic)
        #expect(decision.performance == PerformanceStrategy.maximumPerformance)
        #expect(decision.reasoning.contains("very large") || decision.reasoning.contains("dynamic"))
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_WithCustomHints() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 12)
        let hints = createComplexHints()
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1024,
            deviceType: .pad
        )
        
        // Then
        #expect(decision.columns <= 4) // Respects maxColumns hint
        #expect(decision.spacing >= 16.0) // Respects minSpacing hint
        #expect(decision.performance == PerformanceStrategy.highPerformance) // Respects performanceMode hint
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_DeviceTypeVariations() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 10)
        let hints = createBasicHints()
        
        // Test iPhone
        let iPhoneDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 375,
            deviceType: .phone
        )
        
        // Test iPad
        let iPadDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 768,
            deviceType: .pad
        )
        
        // Then
        #expect(iPhoneDecision.columns <= 2) // iPhone should have fewer columns
        #expect(iPadDecision.columns >= 2) // iPad can have more columns
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_ScreenWidthVariations() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 15)
        let hints = createBasicHints()
        
        // Test narrow screen
        let narrowDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 320,
            deviceType: .phone
        )
        
        // Test wide screen
        let wideDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1200,
            deviceType: .pad
        )
        
        // Then
        #expect(narrowDecision.columns <= 2)
        #expect(wideDecision.columns >= 3)
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_AutoDetection() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 8)
        let hints = createBasicHints()
        
        // When (no screenWidth or deviceType provided)
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints
        )
        
        // Then
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns > 0)
        // IntelligentCardLayoutDecision doesn't have reasoning property
    }
    
    // MARK: - determineOptimalFormLayout_L2 Tests
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_BasicHints() {
        initializeTestConfig()
        // Given
        let hints = createBasicHints()
        
        // When
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.preferredContainer == ContainerPreference.adaptive)
        #expect(decision.fieldLayout == .standard)
        #expect(decision.spacing == .comfortable)
        #expect(decision.validation == .none)
        // IntelligentCardLayoutDecision doesn't have reasoning property
    }
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_ComplexHints() {
        initializeTestConfig()
        // Given
        let hints = createComplexHints()
        
        // When
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.preferredContainer == ContainerPreference.adaptive)
        #expect(decision.fieldLayout == .standard)
        #expect(decision.spacing == .comfortable)
        #expect(decision.validation == .none) // hasValidation not set in hints
        #expect(decision.contentComplexity == .moderate)
    }
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_AccessibilityLevels() {
        initializeTestConfig()
        // Given
        let standardHints = PresentationHints(
            dataType: .form,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .form,
            customPreferences: [:]
        )
        
        let enhancedHints = PresentationHints(
            dataType: .form,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .form,
            customPreferences: ["accessibilityLevel": "enhanced"]
        )
        
        // When
        let standardDecision = determineOptimalFormLayout_L2(hints: standardHints)
        let enhancedDecision = determineOptimalFormLayout_L2(hints: enhancedHints)
        
        // Then
        #expect(standardDecision.spacing == .comfortable)
        #expect(enhancedDecision.spacing == .comfortable)
    }
    
    // MARK: - determineOptimalCardLayout_L2 Tests
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_SmallCardCount() {
        initializeTestConfig()
        // Given
        let cardCount = 3
        let screenWidth: CGFloat = 375
        let deviceType = DeviceType.phone
        
        // When
        let decision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(decision.columns == 1)
        #expect(decision.layout == CardLayoutType.uniform)
        #expect(decision.sizing == CardSizing.adaptive)
        // CardLayoutDecision doesn't have reasoning property
    }
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_MediumCardCount() {
        initializeTestConfig()
        // Given
        let cardCount = 8
        let screenWidth: CGFloat = 768
        let deviceType = DeviceType.pad
        
        // When
        let decision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(decision.columns > 1)
        #expect(decision.layout == CardLayoutType.uniform)
        #expect(decision.sizing == CardSizing.adaptive)
        // CardLayoutDecision doesn't have reasoning property
    }
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_LargeCardCount() {
        initializeTestConfig()
        // Given
        let cardCount = 25
        let screenWidth: CGFloat = 1024
        let deviceType = DeviceType.pad
        
        // When
        let decision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(decision.columns > 2)
        #expect(decision.layout == CardLayoutType.uniform)
        #expect(decision.sizing == CardSizing.adaptive)
        // CardLayoutDecision doesn't have performance or reasoning properties
    }
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_DeviceTypeVariations() {
        initializeTestConfig()
        // Given
        let cardCount = 12
        let screenWidth: CGFloat = 768
        
        // Test iPhone
        let iPhoneDecision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: 375,
            deviceType: .phone,
            contentComplexity: .moderate
        )
        
        // Test iPad
        let iPadDecision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: screenWidth,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(iPhoneDecision.columns <= 2)
        #expect(iPadDecision.columns >= 2)
        #expect(iPhoneDecision.sizing == .adaptive)
        #expect(iPadDecision.sizing == .adaptive)
    }
    
    @Test @MainActor func testDetermineOptimalCardLayout_L2_ScreenWidthVariations() {
        initializeTestConfig()
        // Given
        let cardCount = 15
        let deviceType = DeviceType.pad
        
        // Test narrow screen
        let narrowDecision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: 600,
            deviceType: deviceType,
            contentComplexity: .moderate
        )
        
        // Test wide screen
        let wideDecision = determineOptimalCardLayout_L2(
            contentCount: cardCount,
            screenWidth: 1200,
            deviceType: deviceType,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(narrowDecision.columns <= 3)
        #expect(wideDecision.columns >= 3) // 1200px screen = 3 columns for iPad
    }
    
    // MARK: - determineIntelligentCardLayout_L2 Tests
    
    @Test @MainActor func testDetermineIntelligentCardLayout_L2_Basic() {
        initializeTestConfig()
        // Given
        let contentCount = 10
        let screenWidth: CGFloat = 768
        let deviceType = DeviceType.pad
        
        // When
        let decision = determineIntelligentCardLayout_L2(
            contentCount: contentCount,
            screenWidth: screenWidth,
            deviceType: deviceType,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns > 0)
        #expect(decision.spacing > 0)
        // IntelligentCardLayoutDecision doesn't have reasoning property
    }
    
    @Test @MainActor func testDetermineIntelligentCardLayout_L2_EdgeCases() {
        initializeTestConfig()
        // Test zero content
        let zeroDecision = determineIntelligentCardLayout_L2(
            contentCount: 0,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .simple
        )
        #expect(zeroDecision.columns == 2) // iPad with simple complexity has min 2 columns
        
        // Test single content
        let singleDecision = determineIntelligentCardLayout_L2(
            contentCount: 1,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .simple
        )
        #expect(singleDecision.columns == 2)
        
        // Test very large content
        let largeDecision = determineIntelligentCardLayout_L2(
            contentCount: 1000,
            screenWidth: 1024,
            deviceType: .pad,
            contentComplexity: .veryComplex
        )
        #expect(largeDecision.columns > 1)
    }
    
    // MARK: - OCR and Photo Layout Tests (Simplified)
    
    @Test @MainActor func testOCRLayoutDecision_Basic() {
        initializeTestConfig()
        // Given
        let context = OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8
        )
        
        // When
        let layout = platformOCRLayout_L2(context: context)
        
        // Then
        #expect(Bool(true), "layout is non-optional")  // layout is non-optional
        #expect(layout.maxImageSize.width > 0)
        #expect(layout.maxImageSize.height > 0)
    }
    
    
    // MARK: - Edge Cases and Error Handling
    
    @Test @MainActor func testLayoutDecisionWithInvalidHints() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 5)
        let invalidHints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .browse,
            customPreferences: [
                "invalidKey": "invalidValue",
                "maxColumns": "notANumber"
            ]
        )
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: invalidHints,
            screenWidth: 375,
            deviceType: .phone
        )
        
        // Then
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns > 0)
    }
    
    @Test @MainActor func testLayoutDecisionWithExtremeValues() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 1)
        
        // Test extreme screen width
        let extremeWidthDecision = determineOptimalLayout_L2(
            items: items,
            hints: createBasicHints(),
            screenWidth: 10000,
            deviceType: .pad
        )
        
        // Test zero screen width
        let zeroWidthDecision = determineOptimalLayout_L2(
            items: items,
            hints: createBasicHints(),
            screenWidth: 0,
            deviceType: .phone
        )
        
        // Then
        #expect(Bool(true), "extremeWidthDecision is non-optional")  // extremeWidthDecision is non-optional
        #expect(Bool(true), "zeroWidthDecision is non-optional")  // zeroWidthDecision is non-optional
        #expect(extremeWidthDecision.columns == zeroWidthDecision.columns) // Both extreme values default to 1 column
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testLayoutDecisionIntegration() {
        initializeTestConfig()
        // Given
        let items = createTestItems(count: 20)
        let hints = createComplexHints()
        
        // When
        let layoutDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 768,
            deviceType: .pad
        )
        
        let formDecision = determineOptimalFormLayout_L2(hints: hints)
        
        let cardDecision = determineOptimalCardLayout_L2(
            contentCount: items.count,
            screenWidth: 768,
            deviceType: .pad,
            contentComplexity: .moderate
        )
        
        // Then
        #expect(Bool(true), "layoutDecision is non-optional")  // layoutDecision is non-optional
        #expect(Bool(true), "formDecision is non-optional")  // formDecision is non-optional
        #expect(Bool(true), "cardDecision is non-optional")  // cardDecision is non-optional
        
        // All decisions should be consistent
        #expect(layoutDecision.approach == LayoutApproach.responsive) // 20 items = complex = responsive
        #expect(formDecision.preferredContainer == .adaptive)
        #expect(cardDecision.layout == CardLayoutType.uniform)
    }
}
