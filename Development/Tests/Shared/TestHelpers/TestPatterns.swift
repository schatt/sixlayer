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

#if canImport(ViewInspector)
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
    /// Conforms to Hashable for use with navigation destination APIs
    public struct TestItem: Identifiable, Hashable {
        public let id: AnyHashable
        public let title: String
        
        public init(id: AnyHashable, title: String) {
            self.id = id
            self.title = title
        }
    }
    
    /// Test item for demonstration tests (used by both unit tests and ViewInspector tests)
    public struct DemonstrationTestItem: Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String?
        
        public init(id: String, title: String, subtitle: String? = nil) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
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
    
    #if canImport(ViewInspector)
    /// Verify text (Inspectable view — direct hierarchy).
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsText() instead")
    @MainActor
    public static func verifyViewContainsText<V: View & ViewInspector.Inspectable>(_ view: V, expectedText: String, testName: String) {
        let temp = BaseTestClass()
        temp.verifyViewContainsText(view, expectedText: expectedText, testName: testName)
    }

    /// Verify text (any view — delegates to BaseTestClass).
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsText() instead")
    @MainActor
    public static func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        let temp = BaseTestClass()
        temp.verifyViewContainsText(view, expectedText: expectedText, testName: testName)
    }

    /// Verify image (Inspectable view — direct hierarchy).
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsImage() instead")
    @MainActor
    public static func verifyViewContainsImage<V: View & ViewInspector.Inspectable>(_ view: V, testName: String) {
        let temp = BaseTestClass()
        temp.verifyViewContainsImage(view, testName: testName)
    }

    /// Verify image (any view — delegates to BaseTestClass).
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsImage() instead")
    @MainActor
    public static func verifyViewContainsImage(_ view: some View, testName: String) {
        let temp = BaseTestClass()
        temp.verifyViewContainsImage(view, testName: testName)
    }
    #else
    /// Verify that a view contains specific text content.
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsText() instead")
    @MainActor
    public static func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        let temp = BaseTestClass()
        temp.verifyViewContainsText(view, expectedText: expectedText, testName: testName)
    }

    /// Verify that a view contains specific image elements.
    @available(*, deprecated, message: "Use BaseTestClass.verifyViewContainsImage() instead")
    @MainActor
    public static func verifyViewContainsImage(_ view: some View, testName: String) {
        let temp = BaseTestClass()
        temp.verifyViewContainsImage(view, testName: testName)
    }
    #endif
}
