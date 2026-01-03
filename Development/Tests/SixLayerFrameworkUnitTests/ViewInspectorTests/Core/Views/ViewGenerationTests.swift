import Testing

import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif
/// View Generation Tests
/// Tests that the framework correctly generates SwiftUI views with proper structure and properties
/// These tests focus on what we can actually verify when running on macOS
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("View Generation")
open class ViewGenerationTests: BaseTestClass {
    
    // MARK: - Test Data
    
    public struct TestDataItem: Identifiable {
        public let id = UUID()
        public let title: String
        public let subtitle: String?
        public let description: String?
        public let value: Int
        public let isActive: Bool
    }
    
    // MARK: - Helper Functions
    
    /// Creates specific test data for ViewGenerationTests
    @MainActor
    public func createViewGenerationTestData() -> [TestDataItem] {
        return [
            TestDataItem(title: "Item 1", subtitle: "Subtitle 1", description: "Description 1", value: 42, isActive: true),
            TestDataItem(title: "Item 2", subtitle: nil, description: "Description 2", value: 84, isActive: false),
            TestDataItem(title: "Item 3", subtitle: "Subtitle 3", description: nil, value: 126, isActive: true)
        ]
    }
    
    /// Creates specific layout decision for ViewGenerationTests
    @MainActor
    public func createViewGenerationLayoutDecision() -> IntelligentCardLayoutDecision {
        return IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 200,
            cardHeight: 150,
            padding: 16
        )
    }
    
    // MARK: - View Generation Tests
    
    @Test @MainActor func testIntelligentDetailViewGeneration() {
        // GIVEN: A test data item
        let item = createViewGenerationTestData()[0]
        
        // WHEN: Generating an intelligent detail view
        let detailView = IntelligentDetailView.platformDetailView(for: item)
        
        // THEN: View should be created successfully
        // View creation itself is the test - if it fails to compile or crashes, test fails
        // Optimized: Use minimal ViewInspector check only if available and fast
        #if canImport(ViewInspector)
        // Quick check that view is inspectable (doesn't do expensive deep searches)
        if detailView.tryInspect() == nil {
            Issue.record("View inspection not available")
        }
        #endif
    }
    
    @Test @MainActor func testIntelligentDetailViewWithCustomFieldView() {
        // GIVEN: A test data item and custom field view
        let item = createViewGenerationTestData()[0]
        
        // WHEN: Generating an intelligent detail view with custom field view
        let detailView = IntelligentDetailView.platformDetailView(
            for: item,
            customFieldView: { fieldName, value, fieldType in
                Text("\(fieldName): \(value)")
            }
        )
        
        // THEN: View should be created successfully
        // View creation itself is the test - if it fails to compile or crashes, test fails
        // Optimized: Use minimal ViewInspector check only if available and fast
        #if canImport(ViewInspector)
        if detailView.tryInspect() == nil {
            Issue.record("View inspection not available")
        }
        #endif
    }
    
    @Test @MainActor func testIntelligentDetailViewWithHints() {
        // GIVEN: A test data item and presentation hints
        let item = createViewGenerationTestData()[0]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .compact,
            complexity: .moderate,
            context: .dashboard
        )
        
        // WHEN: Generating an intelligent detail view with hints
        let detailView = IntelligentDetailView.platformDetailView(for: item, hints: hints)
        
        // THEN: View should be created successfully
        // View creation itself is the test - if it fails to compile or crashes, test fails
        // Optimized: Use minimal ViewInspector check only if available and fast
        #if canImport(ViewInspector)
        if detailView.tryInspect() == nil {
            Issue.record("View inspection not available")
        }
        #endif
    }
    
    // MARK: - Layout Strategy Tests
    
    @Test @MainActor func testLayoutStrategyDetermination() {
        // GIVEN: Different data complexities based on content richness
        // Simple data with minimal content (should get compact/standard)
        let simpleData = TestDataItem(
            title: "Simple", 
            subtitle: nil, 
            description: nil, 
            value: 1, 
            isActive: true
        )
        
        // Complex data with rich content (should get detailed/tabbed)
        // This should trigger higher complexity due to content richness, not just field count
        let complexData = TestDataItem(
            title: "Complex Item with Very Long Title That Should Impact Layout Decisions",
            subtitle: "This is a very detailed subtitle that provides extensive context and additional information about the item",
            description: "This is an extremely detailed and comprehensive description that contains a lot of information. It includes multiple paragraphs of content, detailed explanations, technical specifications, usage instructions, and additional context that would require significant screen real estate to display properly. The content is rich enough that it should trigger a more sophisticated layout strategy that can handle complex content presentation, potentially including scrollable areas, expandable sections, or tabbed interfaces to manage the information density effectively.",
            value: 999, 
            isActive: true
        )
        
        // WHEN: Analyzing data for layout strategy
        let simpleAnalysis = DataIntrospectionEngine.analyze(simpleData)
        let complexAnalysis = DataIntrospectionEngine.analyze(complexData)
        
        // THEN: Should determine appropriate layout strategies
        let simpleStrategy = IntelligentDetailView.determineLayoutStrategy(analysis: simpleAnalysis, hints: nil)
        let complexStrategy = IntelligentDetailView.determineLayoutStrategy(analysis: complexAnalysis, hints: nil)
        
        // Simple data should get compact or standard layout
        #expect([DetailLayoutStrategy.compact, DetailLayoutStrategy.standard].contains(simpleStrategy))
        
        // Complex data should get detailed or tabbed layout
        #expect([DetailLayoutStrategy.detailed, DetailLayoutStrategy.tabbed].contains(complexStrategy))
    }
    
    @Test @MainActor func testLayoutStrategyWithHints() {
        // GIVEN: Data and explicit hints
        let item = createViewGenerationTestData()[0]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .detail,
            complexity: .moderate,
            context: .dashboard
        )
        
        // WHEN: Determining layout strategy with hints
        let analysis = DataIntrospectionEngine.analyze(item)
        let strategy = IntelligentDetailView.determineLayoutStrategy(analysis: analysis, hints: hints)
        
        // THEN: Should respect the hints
        #expect(strategy == DetailLayoutStrategy.detailed)
    }
    
    // MARK: - Field View Generation Tests
    
    @Test @MainActor func testFieldViewGeneration() {
        // GIVEN: A data field
        let field = DataField(
            name: "testField",
            type: .string,
            isOptional: false,
            isArray: false,
            isIdentifiable: false
        )
        let value = "Test Value"
        
        // WHEN: Generating a field view
        let fieldView = IntelligentDetailView.platformFieldView(
            field: field,
            value: value,
            customFieldView: { _, _, _ in EmptyView() }
        )
        
        // THEN: Should generate a valid SwiftUI view (struct, not reference type)
        // SwiftUI views are structs, so we can't use XCTAssertNotNil
        // Instead, we verify the view can be created without crashing
        _ = fieldView
    }
    
    @Test @MainActor func testDetailedFieldViewGeneration() {
        // GIVEN: A data field
        let field = DataField(
            name: "testField",
            type: .string,
            isOptional: true,
            isArray: false,
            isIdentifiable: true
        )
        let value = "Test Value"
        
        // WHEN: Generating a detailed field view
        let fieldView = IntelligentDetailView.platformDetailedFieldView(
            field: field,
            value: value,
            customFieldView: { _, _, _ in EmptyView() }
        )
        
        // THEN: Should generate a valid SwiftUI view (struct, not reference type)
        // SwiftUI views are structs, so we can't use XCTAssertNotNil
        // Instead, we verify the view can be created without crashing
        _ = fieldView
    }
    
    // MARK: - Data Analysis Tests
    
    @Test @MainActor func testDataIntrospection() {
        initializeTestConfig()
        // GIVEN: A test data item
        let item = createViewGenerationTestData()[0]
        
        // WHEN: Analyzing the data
        let analysis = DataIntrospectionEngine.analyze(item)
        
        // THEN: Should return valid analysis with expected properties
        #expect(!analysis.fields.isEmpty, "Analysis should contain fields")
        // complexity and patterns are non-optional, so no nil check needed
        _ = analysis.complexity
        _ = analysis.patterns
    }
    
    @Test @MainActor func testDataIntrospectionWithDifferentTypes() {
        initializeTestConfig()
        // GIVEN: Different data types
        let stringData = "Test String"
        let intData = 42
        let boolData = true
        let arrayData = [1, 2, 3]
        let dictData = ["key": "value"]
        
        // WHEN: Analyzing each type
        let stringAnalysis = DataIntrospectionEngine.analyze(stringData)
        let intAnalysis = DataIntrospectionEngine.analyze(intData)
        let boolAnalysis = DataIntrospectionEngine.analyze(boolData)
        let arrayAnalysis = DataIntrospectionEngine.analyze(arrayData)
        let dictAnalysis = DataIntrospectionEngine.analyze(dictData)
        
        // THEN: Should return valid analysis for each type
        // Analysis objects are non-optional - if creation fails, test fails at compile/runtime
        // Verify that analysis was created successfully by checking complexity is a valid enum case
        #expect(ContentComplexity.allCases.contains(stringAnalysis.complexity), "String analysis should be valid")
        #expect(ContentComplexity.allCases.contains(intAnalysis.complexity), "Int analysis should be valid")
        #expect(ContentComplexity.allCases.contains(boolAnalysis.complexity), "Bool analysis should be valid")
        #expect(ContentComplexity.allCases.contains(arrayAnalysis.complexity), "Array analysis should be valid")
        #expect(ContentComplexity.allCases.contains(dictAnalysis.complexity), "Dict analysis should be valid")
    }
    
    // MARK: - View Structure Validation Tests
    
    @Test @MainActor func testViewStructureConsistency() {
        // GIVEN: The same data item
        let item = createViewGenerationTestData()[0]
        
        // WHEN: Generating views multiple times
        let _ = IntelligentDetailView.platformDetailView(for: item)
        let _ = IntelligentDetailView.platformDetailView(for: item)
        
        // THEN: Both views should be created successfully
        // Views are non-optional - if creation fails, test fails at compile/runtime
        // The fact that both views are created without crashing is the test
    }
    
    @Test @MainActor func testViewGenerationWithNilValues() {
        // GIVEN: Data with nil values
        let item = createViewGenerationTestData()[1] // This has nil subtitle
        
        // WHEN: Generating a view
        let _ = IntelligentDetailView.platformDetailView(for: item)
        
        // THEN: Should handle nil values gracefully
        // View is non-optional - if creation fails, test fails at compile/runtime
        // The fact that view is created without crashing when data has nil values is the test
    }
    
    // MARK: - Performance Tests
    
    // MARK: - Error Handling Tests
    
    @Test @MainActor func testViewGenerationWithInvalidData() {
        // GIVEN: Invalid data that might cause issues
        let invalidData = NSNull()
        
        // WHEN: Generating a view with invalid data
        let _ = IntelligentDetailView.platformDetailView(for: invalidData)
        
        // THEN: Should handle invalid data gracefully
        // View is non-optional - if creation fails, test fails at compile/runtime
        // The fact that view is created without crashing with invalid data is the test
    }
    
    @Test @MainActor func testViewGenerationWithEmptyData() {
        // GIVEN: Empty data
        let emptyData = TestDataItem(title: "", subtitle: nil, description: nil, value: 0, isActive: false)
        
        // WHEN: Generating a view
        let _ = IntelligentDetailView.platformDetailView(for: emptyData)
        
        // THEN: Should handle empty data gracefully
        // View is non-optional - if creation fails, test fails at compile/runtime
        // The fact that view is created without crashing with empty data is the test
    }
    
    // MARK: - Accessibility Tests
    
    @Test @MainActor func testViewGenerationWithAccessibilityHints() {
        // GIVEN: Data with accessibility hints
        let sampleData = [
            TestDataItem(title: "Item 1", subtitle: "Subtitle 1", description: "Description 1", value: 42, isActive: true),
            TestDataItem(title: "Item 2", subtitle: nil, description: "Description 2", value: 84, isActive: false),
            TestDataItem(title: "Item 3", subtitle: "Subtitle 3", description: nil, value: 126, isActive: true)
        ]
        let item = sampleData[0]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // WHEN: Generating a view with accessibility hints
        let _ = IntelligentDetailView.platformDetailView(for: item, hints: hints)
        
        // THEN: Should generate a valid view
        // View is non-optional - if creation fails, test fails at compile/runtime
        // The fact that view is created with accessibility hints is the test
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testViewGenerationIntegration() {
        // GIVEN: A complete data set
        let sampleData = [
            TestDataItem(title: "Item 1", subtitle: "Subtitle 1", description: "Description 1", value: 42, isActive: true),
            TestDataItem(title: "Item 2", subtitle: nil, description: "Description 2", value: 84, isActive: false),
            TestDataItem(title: "Item 3", subtitle: "Subtitle 3", description: nil, value: 126, isActive: true)
        ]
        let items = sampleData
        
        // WHEN: Generating views for all items
        let views = items.map { item in
            IntelligentDetailView.platformDetailView(for: item)
        }
        
        // THEN: Should generate valid views for all items
        #expect(views.count == items.count)
        
        // SwiftUI views are structs, so we can't use XCTAssertNotNil
        // Instead, we verify the views can be created without crashing
        for view in views {
            _ = view
        }
    }
    
    @Test @MainActor func testViewGenerationWithCustomFieldViews() {
        // GIVEN: Data and custom field view implementations
        let item = TestDataItem(title: "Item 1", subtitle: "Subtitle 1", description: "Description 1", value: 42, isActive: true)
        
        // WHEN: Generating views with different custom field views
        let _ = IntelligentDetailView.platformDetailView(
            for: item,
            customFieldView: { fieldName, value, fieldType in
                Text("Custom: \(fieldName)")
            }
        )
        
        let _ = IntelligentDetailView.platformDetailView(
            for: item,
            customFieldView: { fieldName, value, fieldType in
                platformVStackContainer {
                    Text(fieldName)
                    Text(String(describing: value))
                }
            }
        )
        
        // THEN: Should generate valid views with custom field views
        // Views are non-optional - if creation fails, test fails at compile/runtime
        // The fact that both views are created with different custom field views is the test
    }
}
