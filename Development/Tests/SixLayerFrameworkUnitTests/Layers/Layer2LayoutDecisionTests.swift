import Testing
import Foundation

//
//  Layer2LayoutDecisionTests.swift
//  SixLayerFrameworkTests
//
//  Layer 2 (Decision) TDD Tests
//  Tests for determineOptimalLayout_L2 and determineOptimalFormLayout_L2 functions
//
//  Test Documentation:
//  Business purpose of function: Determine optimal layout approach and form layout based on content complexity, field count, and device capabilities
//  What are we actually testing:
//    - Content complexity algorithm (0-5=simple, 6-9=moderate, 10-25=complex, 25+=veryComplex)
//    - Layout approach selection (simple=uniform, moderate=adaptive, complex=responsive, veryComplex=dynamic)
//    - Column calculation algorithm with complexity and device limits
//    - Form layout business logic (field count, complexity, validation decisions)
//  HOW are we testing it:
//    - Test content complexity calculation with various field counts and types
//    - Test layout approach selection with different complexity levels
//    - Test column calculation with device width constraints
//    - Test form layout decisions based on field complexity and validation requirements
//    - Validate business logic algorithms rather than just testing existence
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Layer Layout Decision")
open class Layer2LayoutDecisionTests: BaseTestClass {
    
    // MARK: - determineOptimalLayout_L2 Tests
    
    @Test @MainActor func testDetermineOptimalLayout_L2_ContentComplexityAlgorithm() {
        // Test the actual content complexity analysis algorithm
        // Algorithm: 0-5=simple, 6-9=moderate, 10-25=complex, 25+=veryComplex
        
        // Test simple content (0-5 items)
        let simpleItems = (1...3).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let simpleDecision = determineOptimalLayout_L2(
            items: simpleItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .simple, context: .dashboard),
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(simpleDecision.approach == LayoutApproach.uniform, "3 items should result in uniform approach (simple content)")
        
        // Test moderate content (6-9 items)
        let moderateItems = (1...7).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let moderateDecision = determineOptimalLayout_L2(
            items: moderateItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .moderate, context: .dashboard),
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(moderateDecision.approach == LayoutApproach.adaptive, "7 items should result in adaptive approach (moderate content)")
        
        // Test complex content (10-25 items)
        let complexItems = (1...15).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let complexDecision = determineOptimalLayout_L2(
            items: complexItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .complex, context: .dashboard),
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(complexDecision.approach == LayoutApproach.responsive, "15 items should result in responsive approach (complex content)")
        
        // Test very complex content (25+ items)
        let veryComplexItems = (1...30).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let veryComplexDecision = determineOptimalLayout_L2(
            items: veryComplexItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .veryComplex, context: .dashboard),
            screenWidth: 375,
            deviceType: .phone
        )
        #expect(veryComplexDecision.approach == LayoutApproach.dynamic, "30 items should result in dynamic approach (very complex content)")
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_ComplexContent() {
        // Given: Complex content with many items
        let items = (1...50).map { i in
            TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)")
        }
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .grid,
            complexity: .complex,
            context: .dashboard
        )
        
        // When: Determining optimal layout
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1024,
            deviceType: .mac
        )
        
        // Then: Should return appropriate layout decision
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns > 1) // Complex content should use multiple columns
        #expect(decision.spacing > 0)
        #expect(!decision.reasoning.isEmpty)
        #expect(decision.performance == PerformanceStrategy.maximumPerformance) // 50 items = veryComplex = maximumPerformance
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_DifferentDeviceTypes() {
        // Given: Same content for different device types
        let items = (1...20).map { i in
            TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)")
        }
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When: Testing different device types
        let phoneDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 375,
            deviceType: .phone
        )
        
        let padDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 768,
            deviceType: .pad
        )
        
        let macDecision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1440,
            deviceType: .mac
        )
        
        // Then: Should return different decisions based on device capabilities
        #expect(Bool(true), "phoneDecision is non-optional")  // phoneDecision is non-optional
        #expect(Bool(true), "padDecision is non-optional")  // padDecision is non-optional
        #expect(Bool(true), "macDecision is non-optional")  // macDecision is non-optional
        
        // Mac should generally have more columns than phone
        #expect(macDecision.columns >= phoneDecision.columns)
        // Pad should be between phone and mac
        #expect(padDecision.columns >= phoneDecision.columns)
        #expect(padDecision.columns <= macDecision.columns)
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_DifferentComplexityLevels() {
        // Given: Same items with different complexity hints
        let items = (1...10).map { i in
            TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)")
        }
        
        // When: Testing different complexity levels
        let simpleDecision = determineOptimalLayout_L2(
            items: items,
            hints: PresentationHints(
                dataType: .text,
                presentationPreference: .list,
                complexity: .simple,
                context: .dashboard
            ),
            screenWidth: 375,
            deviceType: .phone
        )
        
        let moderateDecision = determineOptimalLayout_L2(
            items: items,
            hints: PresentationHints(
                dataType: .collection,
                presentationPreference: .grid,
                complexity: .moderate,
                context: .dashboard
            ),
            screenWidth: 375,
            deviceType: .phone
        )
        
        let complexDecision = determineOptimalLayout_L2(
            items: items,
            hints: PresentationHints(
                dataType: .collection,
                presentationPreference: .grid,
                complexity: .complex,
                context: .dashboard
            ),
            screenWidth: 375,
            deviceType: .phone
        )
        
        // Then: Performance strategy should increase with item count (not hints complexity)
        #expect(simpleDecision.performance == PerformanceStrategy.highPerformance) // 10 items = complex = highPerformance
        #expect(moderateDecision.performance == PerformanceStrategy.highPerformance) // 10 items = complex = highPerformance  
        #expect(complexDecision.performance == PerformanceStrategy.highPerformance) // 10 items = complex = highPerformance
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_EmptyItems() {
        // Given: Empty items array
        let items: [TestPatterns.TestItem] = []
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .simple,
            context: .dashboard
        )
        
        // When: Determining optimal layout
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 375,
            deviceType: .phone
        )
        
        // Then: Should handle empty array gracefully
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns >= 1) // Should have at least 1 column
        #expect(decision.spacing >= 0)
        #expect(!decision.reasoning.isEmpty)
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_WithoutDeviceContext() {
        // Given: Items without explicit device context
        let items = (1...5).map { i in
            TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)")
        }
        let hints = PresentationHints(
            dataType: .text,
            presentationPreference: .list,
            complexity: .simple,
            context: .dashboard
        )
        
        // When: Determining optimal layout without device context
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints
        )
        
        // Then: Should use auto-detection and return valid decision
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns > 0)
        #expect(decision.spacing >= 0)
        #expect(!decision.reasoning.isEmpty)
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_ColumnCalculationAlgorithm() {
        // Test the actual column calculation algorithm
        // Algorithm: baseColumns = max(1, min(6, itemCount / 3))
        // Then apply complexity limits: simple=3, moderate=4, complex=5, veryComplex=6
        // Then apply device limits: mobile<768=2, tablet>=768=4, desktop>=1024=6
        
        // Test mobile device (width < 768) - should be limited to 2 columns max
        let mobileItems = (1...10).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let mobileDecision = determineOptimalLayout_L2(
            items: mobileItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .complex, context: .dashboard),
            screenWidth: 375, // Mobile width
            deviceType: .phone
        )
        #expect(mobileDecision.columns <= 2, "Mobile devices should be limited to 2 columns max")
        
        // Test tablet device (width >= 768) - should allow more columns
        let tabletItems = (1...10).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let tabletDecision = determineOptimalLayout_L2(
            items: tabletItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .complex, context: .dashboard),
            screenWidth: 768, // Tablet width
            deviceType: .pad
        )
        #expect(tabletDecision.columns > 2, "Tablet devices should allow more than 2 columns")
        #expect(tabletDecision.columns <= 5, "Complex content should be limited to 5 columns")
        
        // Test desktop device (width >= 1024) - should allow maximum columns
        let desktopItems = (1...20).map { i in TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)") }
        let desktopDecision = determineOptimalLayout_L2(
            items: desktopItems,
            hints: PresentationHints(dataType: .text, presentationPreference: .list, complexity: .veryComplex, context: .dashboard),
            screenWidth: 1024, // Desktop width
            deviceType: .pad
        )
        #expect(desktopDecision.columns > 3, "Desktop devices should allow many columns")
        #expect(desktopDecision.columns <= 6, "Very complex content should be limited to 6 columns")
    }
    
    // MARK: - determineOptimalFormLayout_L2 Tests
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_FieldCountComplexityAlgorithm() {
        // Test the actual form complexity analysis algorithm
        // Algorithm: fieldCount >= 8 && hasComplexFields && hasValidation = complex
        //           fieldCount >= 5 = moderate
        //           fieldCount < 5 = simple
        
        // Test simple form (fieldCount < 5)
        let simpleHints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .simple,
            context: .form,
            customPreferences: [
                "fieldCount": "3",
                "hasComplexFields": "false",
                "hasValidation": "false"
            ]
        )
        let simpleDecision = determineOptimalFormLayout_L2(hints: simpleHints)
        #expect(simpleDecision.contentComplexity == .simple, "3 fields should result in simple complexity")
        #expect(simpleDecision.validation == .none, "No validation specified should result in none")
        
        // Test moderate form (fieldCount >= 5)
        let moderateHints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .form,
            customPreferences: [
                "fieldCount": "6",
                "hasComplexFields": "false",
                "hasValidation": "true"
            ]
        )
        let moderateDecision = determineOptimalFormLayout_L2(hints: moderateHints)
        #expect(moderateDecision.contentComplexity == .moderate, "6 fields should result in moderate complexity")
        #expect(moderateDecision.validation == .realTime, "Validation specified should result in realTime")
        
        // Test complex form (fieldCount >= 8 && hasComplexFields && hasValidation)
        let complexHints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .complex,
            context: .form,
            customPreferences: [
                "fieldCount": "10",
                "hasComplexFields": "true",
                "hasValidation": "true"
            ]
        )
        let complexDecision = determineOptimalFormLayout_L2(hints: complexHints)
        #expect(complexDecision.contentComplexity == .complex, "10 fields with complex fields and validation should result in complex complexity")
        #expect(complexDecision.validation == .realTime, "Validation specified should result in realTime")
        
        // Test edge case: many fields but no complex fields or validation
        let edgeHints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .form,
            customPreferences: [
                "fieldCount": "12",
                "hasComplexFields": "false",
                "hasValidation": "false"
            ]
        )
        let edgeDecision = determineOptimalFormLayout_L2(hints: edgeHints)
        #expect(edgeDecision.contentComplexity == .moderate, "12 fields without complex fields should result in moderate complexity")
        #expect(edgeDecision.validation == .none, "No validation specified should result in none")
    }
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_ComplexForm() {
        // Given: Complex form hints
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .complex,
            context: .form,
            customPreferences: [
                "fieldCount": "10",
                "hasComplexFields": "true",
                "hasValidation": "true"
            ]
        )
        
        // When: Determining optimal form layout
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then: Should return appropriate form layout decision
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.preferredContainer == ContainerPreference.adaptive)
        #expect(decision.fieldLayout == .standard)
        #expect(decision.spacing == .comfortable)
        #expect(decision.validation == .realTime)
        #expect(decision.contentComplexity == .complex)
        #expect(!decision.reasoning.isEmpty)
    }
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_ModerateForm() {
        // Given: Moderate form hints
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .form,
            customPreferences: [
                "fieldCount": "6",
                "hasComplexFields": "false",
                "hasValidation": "true"
            ]
        )
        
        // When: Determining optimal form layout
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then: Should return appropriate form layout decision
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.preferredContainer == ContainerPreference.adaptive)
        #expect(decision.fieldLayout == .standard)
        #expect(decision.spacing == .comfortable)
        #expect(decision.validation == .realTime)
        #expect(decision.contentComplexity == .moderate)
        #expect(!decision.reasoning.isEmpty)
    }
    
    @Test @MainActor func testDetermineOptimalFormLayout_L2_DefaultPreferences() {
        // Given: Form hints with default preferences
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .form,
            complexity: .moderate,
            context: .form
        )
        
        // When: Determining optimal form layout
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then: Should use default values
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.preferredContainer == ContainerPreference.adaptive)
        #expect(decision.fieldLayout == .standard)
        #expect(decision.spacing == .comfortable)
        #expect(decision.validation == .none) // Default should be no validation
        #expect(decision.contentComplexity == .moderate) // Default fieldCount=5 = moderate
        #expect(!decision.reasoning.isEmpty)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test @MainActor func testDetermineOptimalLayout_L2_ExtremeValues() {
        // Given: Very large number of items
        let items = (1...1000).map { i in
            TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)")
        }
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .grid,
            complexity: .veryComplex,
            context: .dashboard
        )
        
        // When: Determining optimal layout
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 1920,
            deviceType: .mac
        )
        
        // Then: Should handle extreme values gracefully
        #expect(Bool(true), "decision is non-optional")  // decision is non-optional
        #expect(decision.columns > 0)
        #expect(decision.spacing >= 0)
        #expect(decision.performance == .maximumPerformance) // Very complex should use maximum performance
        #expect(!decision.reasoning.isEmpty)
    }
    
    @Test @MainActor func testDetermineOptimalLayout_L2_DifferentDataTypes() {
        // Given: Different data types
        let items = (1...5).map { i in
            TestPatterns.TestItem(id: "item-\(i)", title: "Item \(i)")
        }
        
        let dataTypes: [DataTypeHint] = Array(DataTypeHint.allCases.prefix(7)) // Use real enum
        
        for dataType in dataTypes {
            let hints = PresentationHints(
                dataType: dataType,
                presentationPreference: .list,
                complexity: .moderate,
                context: .dashboard
            )
            
            // When: Determining optimal layout for each data type
            let decision: GenericLayoutDecision = determineOptimalLayout_L2(
                items: items,
                hints: hints,
                screenWidth: 375,
                deviceType: .phone
            )
            
            // Then: Should return valid decision for each data type
            // decision is a non-optional struct, so it exists if we reach here
            #expect(decision.columns > 0, "Should have positive columns for data type: \(dataType)")
            #expect(decision.spacing >= 0, "Should have non-negative spacing for data type: \(dataType)")
            #expect(!decision.reasoning.isEmpty, "Should have reasoning for data type: \(dataType)")
        }
    }
    
    // MARK: - Performance Tests
    
    // Performance test removed - performance monitoring was removed from framework

}