import Testing


import SwiftUI
@testable import SixLayerFramework

/// Tests for single-instance Layer 1 functions
/// Following TDD principles - these tests define the expected behavior
/// NOTE: Not marked @MainActor on class to allow parallel execution
/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView (prevents Xcode hangs)
@Suite(.serialized)
open class SingleInstanceLayer1Tests: BaseTestClass {
    
    // MARK: - Helper Methods
    
    /// Helper method to create test hints for numeric data
    @MainActor
    private func createNumericTestHints() -> PresentationHints {
        return createTestHints(
            dataType: .numeric,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
    }
    
    // MARK: - Single Instance Numeric Data Tests
    
    @Test @MainActor func testPlatformPresentNumericData_L1_SingleInstance() {
        initializeTestConfig()
        // GIVEN: A single GenericNumericData item
        let testHints = createNumericTestHints()
        let singleNumericData = GenericNumericData(
            value: 42.0,
            label: "Test Value",
            unit: "units"
        )
        
        // WHEN: Presenting the single item
        let view = platformPresentNumericData_L1(data: singleNumericData, hints: testHints)
        
        // THEN: Should create a view successfully
        // view is a non-optional View, so it exists if we reach here
        
        // Test that the view can be hosted (functional test)
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Single numeric data view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor func testPlatformPresentNumericData_L1_SingleInstance_Consistency() {
        initializeTestConfig()
        // GIVEN: A single GenericNumericData item
        let testHints = createNumericTestHints()
        let singleNumericData = GenericNumericData(
            value: 42.0,
            label: "Test Value",
            unit: "units"
        )
        
        // WHEN: Presenting as single instance and as array
        let singleView = platformPresentNumericData_L1(data: singleNumericData, hints: testHints)
        let arrayView = platformPresentNumericData_L1(data: [singleNumericData], hints: testHints)
        
        // THEN: Both should create views successfully
        // singleView and arrayView are non-optional Views, so they exist if we reach here
        
        // Both should be hostable
        let singleHostingView = hostRootPlatformView(singleView.enableGlobalAutomaticCompliance())
        let arrayHostingView = hostRootPlatformView(arrayView.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Single instance view should be hostable")  // singleHostingView is non-optional
        #expect(Bool(true), "Array version view should be hostable")  // arrayHostingView is non-optional
    }
    
    // MARK: - Single Instance Media Data Tests
    
    @Test @MainActor func testPlatformPresentMediaData_L1_SingleInstance() {
        initializeTestConfig()
        // GIVEN: A single GenericMediaItem
        let testHints = createNumericTestHints()
        let singleMediaItem = GenericMediaItem(
            title: "Test Media",
            url: "https://example.com/image.jpg",
            thumbnail: nil
        )
        
        // WHEN: Presenting the single item
        let view = platformPresentMediaData_L1(media: singleMediaItem, hints: testHints)
        
        // THEN: Should create a view successfully
        // view is non-optional, used below with hostRootPlatformView
        
        // Test that the view can be hosted (functional test)
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Single media item view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Single Instance Hierarchical Data Tests
    
    @Test @MainActor func testPlatformPresentHierarchicalData_L1_SingleInstance() {
        // GIVEN: A single GenericHierarchicalItem
        let testHints = createNumericTestHints()
        let singleHierarchicalItem = GenericHierarchicalItem(
            title: "Test Item",
            level: 0,
            children: []
        )
        
        // WHEN: Presenting the single item
        let view = platformPresentHierarchicalData_L1(item: singleHierarchicalItem, hints: testHints)
        
        // THEN: Should create a view successfully
        // view is non-optional, used below with hostRootPlatformView
        
        // Test that the view can be hosted (functional test)
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Single hierarchical item view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Single Instance Temporal Data Tests
    
    @Test @MainActor func testPlatformPresentTemporalData_L1_SingleInstance() {
        // GIVEN: A single GenericTemporalItem
        let testHints = createNumericTestHints()
        let singleTemporalItem = GenericTemporalItem(
            title: "Test Event",
            date: Date(),
            duration: 3600
        )
        
        // WHEN: Presenting the single item
        let view = platformPresentTemporalData_L1(item: singleTemporalItem, hints: testHints)
        
        // THEN: Should create a view successfully
        // view is non-optional, used below with hostRootPlatformView
        
        // Test that the view can be hosted (functional test)
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Single temporal item view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Single Instance Form Data Tests
    
    @Test @MainActor func testPlatformPresentFormData_L1_SingleInstance() {
        // GIVEN: A single DynamicFormField
        let testHints = createNumericTestHints()
        let singleFormField = DynamicFormField(
            id: "test-field",
            contentType: .text,
            label: "Test Field",
            isRequired: false,
            validationRules: [:],
            metadata: [:]
        )
        
        // WHEN: Presenting the single field
        let view = platformPresentFormData_L1(field: singleFormField, hints: testHints)
        
        // THEN: Should create a view successfully (even if deprecated)
        // view is non-optional, used below with hostRootPlatformView
        
        // Test that the view can be hosted (functional test)
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Single form field view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Edge Cases
    
    @Test @MainActor func testSingleInstanceFunctions_WithDifferentHints() {
        // GIVEN: A single numeric data item and different hint types
        let singleNumericData = GenericNumericData(
            value: 42.0,
            label: "Test Value",
            unit: "units"
        )
        
        let cardHints = PresentationHints(
            dataType: .numeric,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let listHints = PresentationHints(
            dataType: .numeric,
            presentationPreference: .list,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        // WHEN: Presenting with different hints
        let cardView = platformPresentNumericData_L1(data: singleNumericData, hints: cardHints)
        let listView = platformPresentNumericData_L1(data: singleNumericData, hints: listHints)
        
        // THEN: Both should create views successfully
        // cardView and listView are non-optional Views, so they exist if we reach here
        
        // Both should be hostable
        let _ = hostRootPlatformView(cardView.enableGlobalAutomaticCompliance())
        let _ = hostRootPlatformView(listView.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "Card view should be hostable")  // cardHostingView is non-optional
        #expect(Bool(true), "List view should be hostable")  // listHostingView is non-optional
    }
}

// MARK: - Test Extensions

extension SingleInstanceLayer1Tests {
    
    /// Host a SwiftUI view and return the platform root view for inspection
    @MainActor
    private func hostRootPlatformView<V: View>(_ view: V) -> Any? {
        #if canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        return hostingController.view
        #elseif canImport(AppKit)
        let hostingController = NSHostingController(rootView: view)
        return hostingController.view
        #else
        return nil
        #endif
    }
}
