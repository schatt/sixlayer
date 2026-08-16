import Testing

//
//  ItemCollectionL1Tests.swift
//  SixLayerFrameworkTests
//
//  Tests for item collection L1 functions
//  Tests generic item collection presentation features
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Item Collection L")
open class ItemCollectionL1Tests: BaseTestClass {
    
    // MARK: - Item Collection Tests
    
    @Test @MainActor func testPlatformPresentItemCollection_L1() {
        initializeTestConfig()
        // Given
        let items = createSampleItems()
        let hints = PresentationHints()
        
        // When
        _ = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here
    }
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithEmptyItems() {
        initializeTestConfig()
        // Given
        let items: [GenericDataItem] = []
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .simple,
            context: .dashboard
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithSingleItem() {
        initializeTestConfig()
        // Given
        let items = [createSampleItems().first!]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .simple,
            context: .browse
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithManyItems() {
        initializeTestConfig()
        // Given
        let items = createManyItems(count: 100)
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .complex,
            context: .browse
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    // MARK: - Different Hint Types
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithCompactHints() {
        initializeTestConfig()
        // Given
        let items = createSampleItems()
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .compact,
            complexity: .simple,
            context: .dashboard
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithDetailedHints() {
        initializeTestConfig()
        // Given
        let items = createSampleItems()
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .detail,
            complexity: .complex,
            context: .detail
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithGridHints() {
        initializeTestConfig()
        // Given
        let items = createSampleItems()
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .browse
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    @Test @MainActor func testPlatformPresentItemCollection_L1_WithListHints() {
        initializeTestConfig()
        // Given
        let items = createSampleItems()
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAItemCollection")
    }
    
    
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
    
}
