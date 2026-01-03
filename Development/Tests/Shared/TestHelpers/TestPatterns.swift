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
    
    // MARK: - Test Case Generation
    
    /// Create boolean test cases for testing enabled/disabled states
    /// Returns array of (Bool, String) tuples for common boolean test patterns
    public static func createBooleanTestCases() -> [(Bool, String)] {
        return [
            (true, "enabled"),
            (false, "disabled")
        ]
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
    
    // MARK: - Verification Factory (Deprecated - Use BaseTestClass methods instead)
    
    /// BUSINESS PURPOSE: Verify that a view is created and contains expected content
    /// DEPRECATED: Use BaseTestClass.verifyViewGeneration() instead
    /// This method is kept for backward compatibility but delegates to BaseTestClass
    @MainActor
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewGeneration() instead")
    public static func verifyViewGeneration(_ view: some View, testName: String) {
        // Create a temporary instance to call the instance method
        // This is a workaround - ideally tests should extend BaseTestClass and call the instance method
        let temp = BaseTestClass()
        temp.verifyViewGeneration(view, testName: testName)
    }
    
    /// BUSINESS PURPOSE: Verify that a view contains specific text content
    /// DEPRECATED: Use BaseTestClass.verifyViewContainsText() instead
    /// This method is kept for backward compatibility but delegates to BaseTestClass
    @MainActor
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsText() instead")
    public static func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        // Create a temporary instance to call the instance method
        // This is a workaround - ideally tests should extend BaseTestClass and call the instance method
        let temp = BaseTestClass()
        temp.verifyViewContainsText(view, expectedText: expectedText, testName: testName)
    }
    
    /// BUSINESS PURPOSE: Verify that a view contains specific image elements
    /// DEPRECATED: Use BaseTestClass.verifyViewContainsImage() instead
    /// This method is kept for backward compatibility but delegates to BaseTestClass
    @MainActor
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsImage() instead")
    public static func verifyViewContainsImage(_ view: some View, testName: String) {
        // Create a temporary instance to call the instance method
        // This is a workaround - ideally tests should extend BaseTestClass and call the instance method
        let temp = BaseTestClass()
        temp.verifyViewContainsImage(view, testName: testName)
    }
}
