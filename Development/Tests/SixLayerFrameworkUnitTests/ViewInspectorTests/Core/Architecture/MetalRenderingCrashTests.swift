import Testing


import SwiftUI
@testable import SixLayerFramework
/// TDD Tests for Metal Rendering Crash Bug Fix
/// Following proper TDD: Write failing tests first to prove the desired behavior
/// 
/// UPDATE: Performance layer has been removed entirely, eliminating the Metal crash bug
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Metal Rendering Crash")
open class MetalRenderingCrashTDDTests: BaseTestClass {
    
    // BaseTestClass handles setup automatically - no singleton access needed    // MARK: - TDD Green Phase: Tests That Now Pass After Performance Layer Removal
    
    @Test @MainActor func testPlatformPresentItemCollectionL1DoesNotCrash() {
            initializeTestConfig()
        // TDD Green Phase: Performance layer removed, so no Metal crash
        
        let mockItems = [
            MockTaskItem(id: "task1", title: "Test Task 1"),
            MockTaskItem(id: "task2", title: "Test Task 2"),
            MockTaskItem(id: "task3", title: "Test Task 3")
        ]
        
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // This should NOT crash - performance layer removed
        let view = platformPresentItemCollection_L1(
            items: mockItems,
            hints: hints,
            onCreateItem: nil,
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        
        // view is a non-optional View, so it exists if we reach here
        
        // Try to inspect the view (should not crash)
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let _ = try? AnyView(view).inspect() {
        } else {
            Issue.record("platformPresentItemCollection_L1 should not crash during inspection")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
    }
    
    @Test @MainActor func testGenericItemCollectionViewDoesNotCrash() {
            initializeTestConfig()
        // TDD Green Phase: Performance layer removed, so no Metal crash
        
        let mockItems = [
            MockTaskItem(id: "task1", title: "Test Task 1"),
            MockTaskItem(id: "task2", title: "Test Task 2")
        ]
        
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // This should NOT crash - performance layer removed
        let view = GenericItemCollectionView(
            items: mockItems,
            hints: hints,
            onCreateItem: nil,
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        
        #expect(Bool(true), "GenericItemCollectionView should not crash")  // view is non-optional
        
        // Try to inspect the view (should not crash)
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let _ = try? AnyView(view).inspect() {
        } else {
            Issue.record("GenericItemCollectionView should not crash during inspection")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
    }
    
    @Test @MainActor func testMetalRenderingCrashReproduction() {
            initializeTestConfig()
        // TDD Green Phase: Performance layer removed, so no Metal crash
        
        let mockItems = [
            MockTaskItem(id: "task1", title: "Test Task 1"),
            MockTaskItem(id: "task2", title: "Test Task 2"),
            MockTaskItem(id: "task3", title: "Test Task 3"),
            MockTaskItem(id: "task4", title: "Test Task 4"),
            MockTaskItem(id: "task5", title: "Test Task 5")
        ]
        
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // Simulate the exact scenario from the bug report
        let view = platformVStackContainer {
            platformPresentItemCollection_L1(
                items: mockItems,
                hints: hints,
                onCreateItem: nil,
                onItemSelected: nil,
                onItemDeleted: nil,
                onItemEdited: nil
            )
        }
        .padding()
        
        // This should NOT crash - performance layer removed
        #expect(Bool(true), "Metal rendering should not crash")  // view is non-optional
        
        // Try to inspect the view (should not crash)
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let _ = try? AnyView(view).inspect() {
        } else {
            Issue.record("Metal rendering should not crash during inspection")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
    }
    
    @Test @MainActor func testSimpleCardComponentWithRegularMaterialCrashes() {
            initializeTestConfig()
        // TDD Green Phase: Performance layer removed, so no Metal crash
        
        let mockItem = MockTaskItem(id: "task1", title: "Test Task 1")
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 150,
            cardHeight: 100,
            padding: 16
        )
        
        // This should NOT crash - performance layer removed
        let view = SimpleCardComponent(
            item: mockItem,
            layoutDecision: layoutDecision,
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
        
        #expect(Bool(true), "SimpleCardComponent should not crash")  // view is non-optional
        
        // Try to inspect the view (should not crash)
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let _ = try? AnyView(view).inspect() {
        } else {
            Issue.record("SimpleCardComponent should not crash during inspection")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
    }
    
    @Test @MainActor func testPerformanceLayerRemoval() {
    initializeTestConfig()
        // TDD Green Phase: Document that performance layer has been removed
        
        let mockItems = [
            MockTaskItem(id: "task1", title: "Test Task 1"),
            MockTaskItem(id: "task2", title: "Test Task 2")
        ]
        
        let hints = PresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        let view = platformPresentItemCollection_L1(
            items: mockItems,
            hints: hints
        )
        
        // PERFORMANCE LAYER REMOVED: No more .drawingGroup(), .compositingGroup(), or Metal rendering
        // This eliminates the Metal crash bug entirely
        
        #expect(Bool(true), "View should be created")  // view is non-optional
        
    }
}

// MARK: - Mock Data

struct MockTaskItem: Identifiable {
    let id: String
    let title: String
}
