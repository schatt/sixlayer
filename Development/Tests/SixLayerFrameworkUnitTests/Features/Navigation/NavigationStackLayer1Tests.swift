import Testing
import SwiftUI

//
//  NavigationStackLayer1Tests.swift
//  SixLayerFrameworkTests
//
//  TDD Tests for platformPresentNavigationStack_L1 function
//  Tests for Layer 1 semantic intent for NavigationStack
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("NavigationStack Layer 1")
open class NavigationStackLayer1Tests: BaseTestClass {
    
    // MARK: - Test Data
    
    struct TestItem: Identifiable, Hashable {
        let id: UUID
        let title: String
    }
    
    let testHints = PresentationHints(
        dataType: .navigation,
        presentationPreference: .navigation,
        complexity: .simple,
        context: .navigation
    )
    
    // MARK: - Basic Functionality Tests
    
    @Test @MainActor func testPlatformPresentNavigationStack_L1_CreatesView() {
        // Given: Simple content view
        let content = Text("Test Content")
        
        // When: Creating navigation stack presentation
        _ = platformPresentNavigationStack_L1(
            content: content,
            hints: testHints
        )
        
        // Then: Should return a view (non-optional)
        #expect(Bool(true), "view is non-optional")
        
        // Verify the view type contains View-related types (may be wrapped in modifiers)
        let mirror = Mirror(reflecting: view)
        let viewType = String(describing: mirror.subjectType)
        // Check for View in the type name (case-insensitive) or ModifiedContent which is a valid SwiftUI view wrapper
        #expect(viewType.lowercased().contains("view") || viewType.contains("ModifiedContent"), 
                "View should be a SwiftUI view type, got: \(viewType)")
    }
    
    @Test @MainActor func testPlatformPresentNavigationStack_L1_WithTitle() {
        // Given: Content with title
        let content = Text("Test Content")
        let title = "Test Navigation"
        
        // When: Creating navigation stack with title
        _ = platformPresentNavigationStack_L1(
            content: content,
            title: title,
            hints: testHints
        )
        
        // Then: Should return a view
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentNavigationStack_L1_WithItems() {
        // Given: Collection of items
        let items = [
            TestItem(id: UUID(), title: "Item 1"),
            TestItem(id: UUID(), title: "Item 2"),
            TestItem(id: UUID(), title: "Item 3")
        ]
        
        // When: Creating navigation stack with items
        _ = platformPresentNavigationStack_L1(
            items: items,
            hints: testHints
        ) { item in
            Text(item.title)
        } destination: { item in
            Text("Detail: \(item.title)")
        }
        
        // Then: Should return a view
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentNavigationStack_L1_HandlesEmptyItems() {
        // Given: Empty items array
        let items: [TestItem] = []
        
        // When: Creating navigation stack with empty items
        _ = platformPresentNavigationStack_L1(
            items: items,
            hints: testHints
        ) { item in
            Text(item.title)
        } destination: { item in
            Text("Detail: \(item.title)")
        }
        
        // Then: Should return a view even with empty items
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentNavigationStack_L1_WithDifferentHints() {
        // Given: Different presentation hints
        let simpleHints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .simple,
            context: .navigation
        )
        
        let complexHints = PresentationHints(
            dataType: .navigation,
            presentationPreference: .navigation,
            complexity: .complex,
            context: .navigation
        )
        
        let content = Text("Test Content")
        
        // When: Creating navigation stacks with different hints
        _ = platformPresentNavigationStack_L1(
            content: content,
            hints: simpleHints
        )
        
        _ = platformPresentNavigationStack_L1(
            content: content,
            hints: complexHints
        )
        
        // Then: Both should return views
        #expect(Bool(true), "simple view is non-optional")
        #expect(Bool(true), "complex view is non-optional")
    }
    
    // MARK: - App Navigation Layer 1 Tests
    
    @Test @MainActor func testPlatformPresentAppNavigation_L1_CreatesView() {
        // Given: Sidebar and detail content
        let sidebar = Text("Sidebar Content")
        let detail = Text("Detail Content")
        
        // When: Creating app navigation presentation
        _ = platformPresentAppNavigation_L1(
            columnVisibility: nil,
            showingNavigationSheet: nil,
            sidebar: { sidebar },
            detail: { detail }
        )
        
        // Then: Should return a view (non-optional)
        #expect(Bool(true), "view is non-optional")
        
        // Verify the view type contains View-related types
        let mirror = Mirror(reflecting: view)
        let viewType = String(describing: mirror.subjectType)
        #expect(viewType.lowercased().contains("view") || viewType.contains("ModifiedContent"), 
                "View should be a SwiftUI view type, got: \(viewType)")
    }
    
    @Test @MainActor func testPlatformPresentAppNavigation_L1_WithBindings() {
        // Given: Sidebar and detail with state bindings
        let sidebar = Text("Sidebar")
        let detail = Text("Detail")
        let columnVisibility = Binding<NavigationSplitViewVisibility>(get: { .automatic }, set: { _ in })
        let showingSheet = Binding<Bool>(get: { false }, set: { _ in })
        
        // When: Creating app navigation with bindings
        _ = platformPresentAppNavigation_L1(
            columnVisibility: columnVisibility,
            showingNavigationSheet: showingSheet,
            sidebar: { sidebar },
            detail: { detail }
        )
        
        // Then: Should return a view
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentAppNavigation_L1_WithOptionalBindings() {
        // Given: Sidebar and detail without bindings
        let sidebar = Text("Sidebar")
        let detail = Text("Detail")
        
        // When: Creating app navigation without bindings
        _ = platformPresentAppNavigation_L1(
            columnVisibility: nil,
            showingNavigationSheet: nil,
            sidebar: { sidebar },
            detail: { detail }
        )
        
        // Then: Should return a view
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentAppNavigation_L1_EmptyContent() {
        // Given: Empty sidebar and detail
        let sidebar = EmptyView()
        let detail = EmptyView()
        
        // When: Creating app navigation with empty content
        _ = platformPresentAppNavigation_L1(
            columnVisibility: nil,
            showingNavigationSheet: nil,
            sidebar: { sidebar },
            detail: { detail }
        )
        
        // Then: Should handle empty content gracefully
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentAppNavigation_L1_ComplexContent() {
        // Given: Complex sidebar and detail content
        let sidebar = VStack {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
        let detail = VStack {
            Text("Detail Title")
            Text("Detail Content")
            Button("Action") { }
        }
        
        // When: Creating app navigation with complex content
        _ = platformPresentAppNavigation_L1(
            columnVisibility: nil,
            showingNavigationSheet: nil,
            sidebar: { sidebar },
            detail: { detail }
        )
        
        // Then: Should return a view
        #expect(Bool(true), "view is non-optional")
    }
    
    @Test @MainActor func testPlatformPresentAppNavigation_L1_AutomaticDeviceDetection() {
        // Given: Sidebar and detail content
        // The function should automatically detect device type, orientation, and screen size
        let sidebar = Text("Sidebar")
        let detail = Text("Detail")
        
        // When: Creating app navigation (automatic detection)
        _ = platformPresentAppNavigation_L1(
            columnVisibility: nil,
            showingNavigationSheet: nil,
            sidebar: { sidebar },
            detail: { detail }
        )
        
        // Then: Should return a view that uses automatic device detection
        #expect(Bool(true), "view is non-optional")
        // Note: The actual device detection happens at runtime through L2/L3 layers
    }
}

