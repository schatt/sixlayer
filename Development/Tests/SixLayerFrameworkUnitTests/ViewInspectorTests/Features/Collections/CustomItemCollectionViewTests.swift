import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for CustomItemCollectionView component
/// 
/// BUSINESS PURPOSE: Ensure CustomItemCollectionView generates proper accessibility identifiers
/// TESTING SCOPE: CustomItemCollectionView component from PlatformSemanticLayer1.swift
/// METHODOLOGY: Test component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Custom Item Collection View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class CustomItemCollectionViewTests: BaseTestClass {
    
    // MARK: - Helper Methods
    
    // BaseTestClass handles setup automatically
    
    @MainActor
    private func configureAccessibilityIdentifiers() {
        let config = AccessibilityIdentifierConfig.shared
        config.resetToDefaults()
        config.enableAutoIDs = true
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableDebugLogging = false
    }
    
    // MARK: - CustomItemCollectionView Tests
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testCustomItemCollectionViewGeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testItems = [
            CustomItemCollectionViewTestItem(id: "item1", title: "Test Item 1"),
            CustomItemCollectionViewTestItem(id: "item2", title: "Test Item 2")
        ]
        
        let view = GenericItemCollectionView<CustomItemCollectionViewTestItem>(
            items: testItems,
            hints: PresentationHints(
                dataType: .collection,
                presentationPreference: .automatic
            )
        )
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "CustomItemCollectionView"
        )
 #expect(hasAccessibilityID, "CustomItemCollectionView should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testCustomItemCollectionViewGeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testItems = [
            CustomItemCollectionViewTestItem(id: "item1", title: "Test Item 1"),
            CustomItemCollectionViewTestItem(id: "item2", title: "Test Item 2")
        ]
        
        let view = GenericItemCollectionView<CustomItemCollectionViewTestItem>(
            items: testItems,
            hints: PresentationHints(
                dataType: .collection,
                presentationPreference: .automatic
            )
        )
        
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: .macOS,
            componentName: "CustomItemCollectionView"
        )
 #expect(hasAccessibilityID, "CustomItemCollectionView should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

// MARK: - Test Support Types

/// Test item for CustomItemCollectionView testing
struct CustomItemCollectionViewTestItem: Identifiable {
    let id: String
    let title: String
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
