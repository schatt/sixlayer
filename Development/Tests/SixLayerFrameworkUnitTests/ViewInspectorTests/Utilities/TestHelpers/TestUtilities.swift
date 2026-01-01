import Foundation
import SwiftUI
@testable import SixLayerFramework

// MARK: - Shared Test Data Models

public struct TestItem: Identifiable, CardDisplayable, Hashable, @unchecked Sendable {
    public let id: AnyHashable
    public let title: String
    public let subtitle: String?
    public let description: String?
    public let icon: String?
    public let color: Color?
    public let value: Any?
    
    // Constructor with auto-generated UUID ID
    public init(title: String, subtitle: String? = nil, description: String? = nil, icon: String? = nil, color: Color? = nil, value: Any? = nil) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.icon = icon
        self.color = color
        self.value = value
    }
    
    // Constructor with explicit ID (String or UUID)
    init(id: AnyHashable, title: String, subtitle: String? = nil, description: String? = nil, icon: String? = nil, color: Color? = nil, value: Any? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.icon = icon
        self.color = color
        self.value = value
    }
    
    public var cardTitle: String { title }
    public var cardSubtitle: String? { subtitle }
    public var cardDescription: String? { description }
    public var cardIcon: String? { icon }
    public var cardColor: Color? { color }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(description)
        hasher.combine(icon)
    }
    
    public static func == (lhs: TestItem, rhs: TestItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.subtitle == rhs.subtitle &&
               lhs.description == rhs.description &&
               lhs.icon == rhs.icon
    }
}

struct MockItem: Identifiable {
    let id: Int
}

struct MockNavigationItem: Identifiable, Hashable {
    let id: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MockNavigationItem, rhs: MockNavigationItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MockHierarchicalData {
    let id = UUID()
    let name = "Root"
    let children: [MockHierarchicalData] = []
}

// MARK: - Test Helper Functions

func createTestHints(
    dataType: DataTypeHint = .collection,
    presentationPreference: PresentationPreference = .automatic,
    complexity: ContentComplexity = .moderate,
    context: PresentationContext = .dashboard,
    customPreferences: [String: String] = [:]
) -> PresentationHints {
    return PresentationHints(
        dataType: dataType,
        presentationPreference: presentationPreference,
        complexity: complexity,
        context: context,
        customPreferences: customPreferences
    )
}
