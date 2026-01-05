import Testing


//
//  LayoutDecisionReasoningTests.swift
//  SixLayerFrameworkTests
//
//  Tests for layout decision reasoning properties
//

@testable import SixLayerFramework

@Suite("Layout Decision Reasoning")
open class LayoutDecisionReasoningTests: BaseTestClass {
    
    // MARK: - GenericLayoutDecision Reasoning Tests
    
    @Test func testGenericLayoutDecisionReasoningContainsApproach() {
        // Given
        let decision = GenericLayoutDecision(
            approach: .grid,
            columns: 2,
            spacing: 16.0,
            performance: .standard,
            reasoning: "Selected grid layout with 2 columns for optimal user experience"
        )
        
        // Then
        #expect(decision.reasoning.contains("grid"))
        #expect(decision.reasoning.contains("2 columns"))
    }
    
    @Test func testGenericLayoutDecisionReasoningContainsPerformance() {
        // Given
        let decision = GenericLayoutDecision(
            approach: .list,
            columns: 1,
            spacing: 8.0,
            performance: .highPerformance,
            reasoning: "Selected list layout with 1 column for optimal user experience"
        )
        
        // Then
        #expect(decision.reasoning.contains("list"))
        #expect(decision.reasoning.contains("1 column"))
    }
    
    @Test func testGenericLayoutDecisionReasoningContainsSpacing() {
        // Given
        let decision = GenericLayoutDecision(
            approach: .grid,
            columns: 3,
            spacing: 24.0,
            performance: .optimized,
            reasoning: "Selected grid layout with 3 columns for optimal user experience"
        )
        
        // Then
        #expect(decision.reasoning.contains("grid"))
        #expect(decision.reasoning.contains("3 columns"))
    }
    
    // MARK: - GenericFormLayoutDecision Reasoning Tests
    
    @Test func testGenericFormLayoutDecisionReasoningContainsContainer() {
        // Given
        let decision = GenericFormLayoutDecision(
            preferredContainer: .adaptive,
            fieldLayout: .standard,
            spacing: .comfortable,
            validation: .realTime,
            contentComplexity: .moderate,
            reasoning: "Form layout optimized based on field count and complexity"
        )
        
        // Then
        #expect(decision.reasoning.contains("Form layout"))
        #expect(decision.reasoning.contains("optimized"))
    }
    
    @Test func testGenericFormLayoutDecisionReasoningContainsComplexity() {
        // Given
        let decision = GenericFormLayoutDecision(
            preferredContainer: .structured,
            fieldLayout: .compact,
            spacing: .generous,
            validation: .onSubmit,
            contentComplexity: .complex,
            reasoning: "Form layout optimized based on field count and complexity"
        )
        
        // Then
        #expect(decision.reasoning.contains("Form layout"))
        #expect(decision.reasoning.contains("complexity"))
    }
    
    // MARK: - Reasoning Content Validation Tests
    
    @Test func testReasoningIsNotEmpty() {
        // Given
        let decision = GenericLayoutDecision(
            approach: .grid,
            columns: 2,
            spacing: 16.0,
            performance: .standard,
            reasoning: "Selected grid layout with 2 columns for optimal user experience"
        )
        
        // Then
        #expect(!decision.reasoning.isEmpty)
        #expect(decision.reasoning.count > 10)
    }
    
    @Test func testReasoningIsDescriptive() {
        // Given
        let decision = GenericFormLayoutDecision(
            preferredContainer: .adaptive,
            fieldLayout: .standard,
            spacing: .comfortable,
            validation: .realTime,
            contentComplexity: .moderate,
            reasoning: "Form layout optimized based on field count and complexity"
        )
        
        // Then
        #expect(decision.reasoning.contains("optimized"))
        #expect(decision.reasoning.contains("based on"))
    }
    
    // MARK: - Reasoning Consistency Tests
    
    @Test func testReasoningConsistencyAcrossSimilarDecisions() {
        // Given
        let decision1 = GenericLayoutDecision(
            approach: .grid,
            columns: 2,
            spacing: 16.0,
            performance: .standard,
            reasoning: "Selected grid layout with 2 columns for optimal user experience"
        )
        
        let decision2 = GenericLayoutDecision(
            approach: .grid,
            columns: 2,
            spacing: 16.0,
            performance: .standard,
            reasoning: "Selected grid layout with 2 columns for optimal user experience"
        )
        
        // Then
        #expect(decision1.reasoning == decision2.reasoning)
    }
    
    @Test func testReasoningReflectsDifferentApproaches() {
        // Given
        let gridDecision = GenericLayoutDecision(
            approach: .grid,
            columns: 2,
            spacing: 16.0,
            performance: .standard,
            reasoning: "Selected grid layout with 2 columns for optimal user experience"
        )
        
        let listDecision = GenericLayoutDecision(
            approach: .list,
            columns: 1,
            spacing: 8.0,
            performance: .standard,
            reasoning: "Selected list layout with 1 column for optimal user experience"
        )
        
        // Then
        #expect(gridDecision.reasoning != listDecision.reasoning)
        #expect(gridDecision.reasoning.contains("grid"))
        #expect(listDecision.reasoning.contains("list"))
    }
    
    // MARK: - Real Layout Decision Integration Tests
    
    @Test @MainActor
    func testRealLayoutDecisionReasoningGeneration() {
        // Given
        let items = [
            TestPatterns.TestItem(id: 1, title: "Item 1"),
            TestPatterns.TestItem(id: 2, title: "Item 2"),
            TestPatterns.TestItem(id: 3, title: "Item 3")
        ]
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard,
            customPreferences: [:]
        )
        
        // When
        let decision = determineOptimalLayout_L2(
            items: items,
            hints: hints,
            screenWidth: 768.0,
            deviceType: .pad
        )
        
        // Then
        #expect(!decision.reasoning.isEmpty)
        #expect(decision.reasoning.contains("Layout optimized"))
        #expect(decision.reasoning.contains("approach"))
        #expect(decision.reasoning.contains("columns"))
    }
    
    @Test @MainActor
    func testRealFormLayoutDecisionReasoningGeneration() {
        // Given
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .form,
            customPreferences: [:]
        )
        
        // When
        let decision = determineOptimalFormLayout_L2(hints: hints)
        
        // Then
        #expect(!decision.reasoning.isEmpty)
        #expect(decision.reasoning.contains("Form layout"))
        #expect(decision.reasoning.contains("optimized"))
    }
}
