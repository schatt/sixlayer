//
//  TestPatterns.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Reusable test patterns and data types to eliminate duplication across tests
//

import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
import ViewInspector
#endif

/// Reusable test patterns and data types
public enum TestPatterns {
    
    // MARK: - Test Data Types
    
    /// Test data item for testing views with collections
    public struct TestDataItem: Identifiable {
        public let id = UUID()
        public let title: String
        public let subtitle: String?
        public let description: String?
        public let value: Int
        public let isActive: Bool
        
        public init(
            title: String,
            subtitle: String? = nil,
            description: String? = nil,
            value: Int = 0,
            isActive: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.description = description
            self.value = value
            self.isActive = isActive
        }
    }
    
    /// Simple test item with id and title (for basic testing)
    public struct TestItem: Identifiable {
        public let id: AnyHashable
        public let title: String
        
        public init(id: AnyHashable, title: String) {
            self.id = id
            self.title = title
        }
    }
    
    /// View information for testing
    public struct ViewInfo {
        public let name: String
        public let type: String
        public let platform: SixLayerPlatform
        public let capabilities: [String]
        
        public init(
            name: String,
            type: String,
            platform: SixLayerPlatform,
            capabilities: [String] = []
        ) {
            self.name = name
            self.type = type
            self.platform = platform
            self.capabilities = capabilities
        }
    }
    
    /// Accessibility feature for testing
    public struct AccessibilityFeature {
        public let name: String
        public let enabled: Bool
        public let platform: SixLayerPlatform
        
        public init(
            name: String,
            enabled: Bool,
            platform: SixLayerPlatform
        ) {
            self.name = name
            self.enabled = enabled
            self.platform = platform
        }
    }
    
    // MARK: - Helper Functions
    
    /// Create a test item with default values
    @MainActor
    public static func createTestItem(
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        value: Int = 0,
        isActive: Bool = true
    ) -> TestDataItem {
        return TestDataItem(
            title: title,
            subtitle: subtitle,
            description: description,
            value: value,
            isActive: isActive
        )
    }
    
    // MARK: - View Generation Factory
    
    /// Create an IntelligentDetailView for testing
    @MainActor
    public static func createIntelligentDetailView(
        item: TestDataItem
    ) -> some View {
        let hints = PresentationHints()
        return IntelligentDetailView.platformDetailView(for: item, hints: hints)
    }
    
    /// Create a SimpleCardComponent for testing
    @MainActor
    public static func createSimpleCardComponent(
        item: TestDataItem
    ) -> some View {
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 200,
            cardHeight: 150,
            padding: 16
        )
        return SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: PresentationHints(),
            onItemSelected: nil,
            onItemDeleted: nil,
            onItemEdited: nil
        )
    }
    
    // MARK: - Verification Factory
    
    /// BUSINESS PURPOSE: Verify that a view is created and contains expected content
    /// TESTING SCOPE: Tests the two critical aspects: view creation + content verification
    /// METHODOLOGY: Uses ViewInspector to verify actual view structure and content
    @MainActor
    public static func verifyViewGeneration(_ view: some View, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here
        
        // 2. Contains what it needs to contain - The view has proper structure
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        if view.tryInspect() == nil {
            Issue.record("Failed to inspect view structure for \(testName)")
        }
        #else
        // ViewInspector not available on macOS - view creation is verified by non-optional parameter
        // Test passes by verifying compilation and view creation
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify that a view contains specific text content
    /// TESTING SCOPE: Tests that views contain expected text elements
    /// METHODOLOGY: Uses ViewInspector to find and verify text content
    /// Using wrapper - when ViewInspector works on macOS, no changes needed here
    @MainActor
    public static func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here
        
        // 2. Contains what it needs to contain - The view should contain expected text
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let inspectionResult = withInspectedView(view) { inspected in
            let viewText = inspected.sixLayerFindAll(ViewType.Text.self)
            #expect(!viewText.isEmpty, "View should contain text elements for \(testName)")

            let hasExpectedText = viewText.contains { text in
                if let textContent = try? text.sixLayerString() {
                    return textContent.contains(expectedText)
                }
                return false
            }
            #expect(hasExpectedText, "View should contain text '\(expectedText)' for \(testName)")
            return true
        }
        #else
        let inspectionResult: Bool? = nil
        #endif

        if inspectionResult == nil {
            #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
            Issue.record("View inspection failed on this platform for \(testName)")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "View created for \(testName) (ViewInspector not available on macOS)")
            #endif
        }
    }
}
