//
//  TestPatterns.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Reusable test patterns and data types to eliminate duplication across tests
//

import Foundation
import SwiftUI
@testable import SixLayerFramework

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
}
