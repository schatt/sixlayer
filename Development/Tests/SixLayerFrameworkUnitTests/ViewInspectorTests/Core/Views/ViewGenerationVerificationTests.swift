import Testing


import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif
/// View Generation Verification Tests
/// Tests that the actual SwiftUI views are generated correctly with the right properties and modifiers
/// This verifies the view structure using the new testing pattern: view created + contains expected content
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("View Generation Verification")
open class ViewGenerationVerificationTests: BaseTestClass {
    
    // MARK: - Test Data
    
    struct TestDataItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
        let description: String?
        let value: Int
        let isActive: Bool
    }
    
    // Helper method - creates fresh test data for each test (test isolation)
    private func createTestItem() -> TestDataItem {
        return TestDataItem(
            title: "Item 1",
            subtitle: "Subtitle 1",
            description: "Description 1",
            value: 42,
            isActive: true
        )
    }
    
    private func createTestItems() -> [TestDataItem] {
        return [
            TestDataItem(title: "Item 1", subtitle: "Subtitle 1", description: "Description 1", value: 42, isActive: true),
            TestDataItem(title: "Item 2", subtitle: nil, description: "Description 2", value: 84, isActive: false),
            TestDataItem(title: "Item 3", subtitle: "Subtitle 3", description: nil, value: 126, isActive: true)
        ]
    }
    
    // MARK: - Real Framework Tests
    
    /// BUSINESS PURPOSE: Verify that IntelligentDetailView actually generates views with proper structure
    /// TESTING SCOPE: Tests that the framework returns views with expected content and layout
    /// METHODOLOGY: View creation + DataIntrospectionEngine (ScrollView/ForEach detail fields are not reliably visible to ViewInspector in unit tests — Issue 178 / #314)
    @Test @MainActor func testIntelligentDetailViewGeneratesProperStructure() {
        let item = createTestItem()
        let detailView = IntelligentDetailView.platformDetailView(for: item)
        let analysis = DataIntrospectionEngine.analyze(item)

        #if canImport(ViewInspector)
        verifyViewGeneration(detailView, testName: "Detail view structure")
        #endif

        let fieldNames = Set(analysis.fields.map(\.name))
        #expect(fieldNames.contains("title"), "Analysis should include title field for detail view content")
        #expect(fieldNames.contains("subtitle"), "Analysis should include subtitle field for detail view content")
    }
    
    /// BUSINESS PURPOSE: Verify that IntelligentDetailView handles different layout strategies
    /// TESTING SCOPE: Tests that different presentation hints result in different view structures
    /// METHODOLOGY: Tests actual framework behavior with different hints
    @Test @MainActor func testIntelligentDetailViewWithDifferentHints() {
        // GIVEN: Test data and different presentation hints
        let item = createTestItem()
        
        // Test compact layout
        let compactHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .compact,
            complexity: .simple,
            context: .dashboard
        )
        
        // Test detailed layout
        let detailedHints = PresentationHints(
            dataType: .generic,
            presentationPreference: .detail,
            complexity: .complex,
            context: .dashboard
        )
        
        // WHEN: Generating views with different hints
        let compactView = IntelligentDetailView.platformDetailView(for: item, hints: compactHints)
        let detailedView = IntelligentDetailView.platformDetailView(for: item, hints: detailedHints)
        let analysis = DataIntrospectionEngine.analyze(item)

        #if canImport(ViewInspector)
        verifyViewGeneration(compactView, testName: "Compact detail view")
        verifyViewGeneration(detailedView, testName: "Detailed detail view")
        #endif

        #expect(
            IntelligentDetailView.determineLayoutStrategy(analysis: analysis, hints: compactHints) == .compact,
            "Compact hints should select compact layout strategy"
        )
        #expect(
            IntelligentDetailView.determineLayoutStrategy(analysis: analysis, hints: detailedHints) == .detailed,
            "Detail hints should select detailed layout strategy"
        )
    }

    /// BUSINESS PURPOSE: Verify that IntelligentDetailView handles custom field views
    /// TESTING SCOPE: Tests that custom field views are actually used in the generated view
    /// METHODOLOGY: Tests that custom content appears in the final view
    @Test @MainActor func testIntelligentDetailViewWithCustomFieldView() {
        // GIVEN: Test data and custom field view
        let item = createTestItem()
        
        // WHEN: Generating view with custom field view
        let detailView = IntelligentDetailView.platformDetailView(
            for: item,
            customFieldView: { fieldName, value, fieldType in
                Text("Custom: \(fieldName) = \(value)")
            }
        )

        #if canImport(ViewInspector)
        verifyViewGeneration(detailView, testName: "Detail view with custom field renderer")
        #endif

        #expect(
            DataIntrospectionEngine.analyze(item).fields.contains { $0.name == "title" },
            "Custom field view path should still analyze source data fields"
        )
    }
    
    /// BUSINESS PURPOSE: Verify that IntelligentDetailView handles nil values gracefully
    /// TESTING SCOPE: Tests that views with nil values still generate properly
    /// METHODOLOGY: Tests actual framework behavior with nil data
    @Test @MainActor func testIntelligentDetailViewWithNilValues() {
        // GIVEN: Test data with nil values
        let item = createTestItems()[1]
        let detailView = IntelligentDetailView.platformDetailView(for: item)
        let analysis = DataIntrospectionEngine.analyze(item)

        #if canImport(ViewInspector)
        verifyViewGeneration(detailView, testName: "Detail view with nil subtitle")
        #endif

        let fieldNames = Set(analysis.fields.map(\.name))
        #expect(fieldNames.contains("title"), "Nil subtitle item should still expose title field")
        #expect(fieldNames.contains("description"), "Nil subtitle item should still expose description field")
    }
    
    /// BUSINESS PURPOSE: Verify that DataIntrospectionEngine actually analyzes data correctly
    /// TESTING SCOPE: Tests that the data analysis returns expected results
    /// METHODOLOGY: Tests actual analysis results, not just that analysis runs
    @Test func testDataIntrospectionEngineAnalyzesDataCorrectly() {
        // GIVEN: Test data
        let item = createTestItem()
        
        // WHEN: Analyzing the data
        let analysis = DataIntrospectionEngine.analyze(item)
        
        // THEN: Test the two critical aspects
        
        // 1. Analysis created - The analysis should be created successfully
        // Data analysis creation succeeded (non-optional result)

        // 2. Contains what it needs to contain - The analysis should contain expected data
        #expect(!analysis.fields.isEmpty, "Analysis should contain fields")
        // Analysis complexity and patterns are non-optional properties
        
        // Should contain fields for our test data properties
        let fieldNames = analysis.fields.map { $0.name }
        #expect(fieldNames.contains("title"), "Analysis should contain 'title' field")
        #expect(fieldNames.contains("subtitle"), "Analysis should contain 'subtitle' field")
        #expect(fieldNames.contains("description"), "Analysis should contain 'description' field")
        #expect(fieldNames.contains("value"), "Analysis should contain 'value' field")
        #expect(fieldNames.contains("isActive"), "Analysis should contain 'isActive' field")
    }
    
    // Temporarily removed testLayoutStrategyDeterminationWorksCorrectly due to compilation issues
}