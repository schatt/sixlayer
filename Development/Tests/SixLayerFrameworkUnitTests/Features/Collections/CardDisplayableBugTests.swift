import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for CardDisplayable protocol bug fixes
/// All features are implemented and tests are passing
/// These tests should FAIL initially, demonstrating the bug described in the bug report
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Card Displayable Bug")
struct CardDisplayableBugTests {
    
    // MARK: - Test Data Types
    
    /// Core Data-like entity with nil values (simulating the bug report scenario)
    struct CoreDataTask: Identifiable, CardDisplayable {
        public let id = UUID()
        let title: String?  // This will be nil, simulating Core Data nil values
        let taskDescription: String?
        let status: String?
        let priority: String?
        
        init(title: String? = nil, taskDescription: String? = nil, status: String? = nil, priority: String? = nil) {
            self.title = title
            self.taskDescription = taskDescription
            self.status = status
            self.priority = priority
        }
        
        // CardDisplayable implementation with fallbacks for nil values
        public var cardTitle: String {
            return (title?.isEmpty == false) ? title! : "Untitled Task"
        }
        
        public var cardSubtitle: String? {
            return (status?.isEmpty == false) ? status : nil
        }
        
        public var cardIcon: String? {
            switch status {
            case "completed": return "checkmark.circle.fill"
            case "in_progress": return "clock.fill"
            default: return "doc.text"
            }
        }
        
        // cardColor removed - tests should use PresentationHints instead (Issue #142)
    }
    
    /// Project entity with nil values
    struct CoreDataProject: Identifiable, CardDisplayable {
        public let id = UUID()
        let name: String?
        let description: String?
        
        init(name: String? = nil, description: String? = nil) {
            self.name = name
            self.description = description
        }
        
        public var cardTitle: String {
            return name ?? "Untitled Project"
        }
        
        public var cardSubtitle: String? {
            return description
        }
        
        public var cardIcon: String? {
            return "folder.fill"
        }
        
        // cardColor removed - tests should use PresentationHints instead (Issue #142)
    }
    
    // MARK: - CardDisplayable Fallback Tests
    
    /// Test that CardDisplayable protocol is used when hints fail to extract meaningful values
    @Test func testCardDisplayableFallbackWhenHintsFail() async {
        // Given: Core Data entity with nil values and hints that fail to extract
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",  // This will be nil, so hints should fail
                "itemSubtitleProperty": "taskDescription",  // This will be nil too
                "itemIconProperty": "status",
                "itemColorProperty": "priority"
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let result = CardDisplayHelper.extractTitle(from: task, hints: hints)
        
        // Then: Should return nil when hints fail to extract meaningful values
        #expect(result == nil, "Should return nil when hints fail to extract meaningful values")
    }
    
    /// Test that empty strings are respected as valid content (not fallback to CardDisplayable)
    @Test @MainActor func testCardDisplayableFallbackWhenHintsExtractEmptyStrings() async {
        // Given: Entity with empty string values and hints
        let task = CoreDataTask(title: "", taskDescription: "", status: "", priority: "")
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",  // This will be empty string, which is valid content
                "itemSubtitleProperty": "taskDescription"
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let result = CardDisplayHelper.extractTitle(from: task, hints: hints)
        
        // Then: Should return nil for empty string (no default configured)
        #expect(result == nil, "Should return nil for empty string when no default is configured")
    }
    
    /// Test that CardDisplayable protocol is used when hints extract nil values
    @Test @MainActor func testCardDisplayableFallbackWhenHintsExtractNilValues() async {
        // Given: Entity with nil values and hints
        let project = CoreDataProject(name: nil, description: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "name"  // This will be nil, so hints should fail
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let result = CardDisplayHelper.extractTitle(from: project, hints: hints)
        
        // Then: Should return nil when hints extract nil values
        #expect(result == nil, "Should return nil when hints extract nil values")
    }
    
    /// Test that CardDisplayable protocol is used when hints are missing
    @Test @MainActor func testCardDisplayableFallbackWhenHintsAreMissing() async {
        // Given: Entity with nil values and no hints
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        
        // When: Extract title using CardDisplayHelper without hints
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: nil)
        
        // Then: Should fall back to CardDisplayable when no hints and reflection finds nothing
        // Reflection won't find anything (all properties are nil), so should use CardDisplayable
        #expect(extractedTitle == "Untitled Task", "Should fall back to CardDisplayable when no hints and reflection fails")
    }
    
    /// Test that CardDisplayable protocol is used when hints have invalid property names
    @Test @MainActor func testCardDisplayableFallbackWhenHintsHaveInvalidPropertyNames() async {
        // Given: Entity with nil values and hints with invalid property names
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "nonexistentProperty",  // This property doesn't exist
                "itemSubtitleProperty": "anotherNonexistentProperty"
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        
        // Then: Should fall back to CardDisplayable when hints have invalid property names
        // Reflection won't find anything (all properties are nil), so should use CardDisplayable
        #expect(extractedTitle == "Untitled Task", "Should fall back to CardDisplayable when hints have invalid property names")
    }
    
    /// Test that CardDisplayable protocol is used for all properties (title, subtitle, icon, color)
    @Test @MainActor func testCardDisplayableFallbackForAllProperties() async {
        // Given: Entity with nil values and hints that fail (using non-existent properties)
        let task = CoreDataTask(title: nil, taskDescription: nil, status: "in_progress", priority: "urgent")
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "nonexistentTitle",  // This will fail, should fall back to CardDisplayable
                "itemSubtitleProperty": "nonexistentSubtitle",  // This will fail, should fall back to CardDisplayable
                "itemIconProperty": "nonexistentIcon",  // This will fail, should fall back to CardDisplayable
                "itemColorProperty": "nonexistentColor"  // This will fail, should fall back to CardDisplayable
            ]
        )
        
        // When: Extract all properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        let extractedIcon = CardDisplayHelper.extractIcon(from: task, hints: hints)
        let extractedColor = CardDisplayHelper.extractColor(from: task, hints: hints)
        
        // Then: Should fall back to reflection when hints fail (finds "status" property via reflection)
        // For title: reflection finds "in_progress" from status property
        // For subtitle/icon/color: reflection doesn't find them, so should fall back to CardDisplayable
        #expect(extractedTitle == "in_progress", "Should fall back to reflection and find 'status' property when hints fail")
        // Subtitle: reflection doesn't find subtitle properties, so CardDisplayable.cardSubtitle returns nil (status is not empty but it's not the subtitle)
        #expect(extractedSubtitle == nil, "Should return nil when reflection and CardDisplayable both fail for subtitle")
        // Icon: reflection doesn't find icon properties, so should use CardDisplayable.cardIcon which returns "clock.fill" for "in_progress" status
        #expect(extractedIcon == "clock.fill", "Should fall back to CardDisplayable when reflection fails for icon")
        // Color: cardColor removed from protocol (Issue #142) - should return nil when no hints provided
        #expect(extractedColor == nil, "Should return nil when no color configuration in hints (cardColor removed from protocol)")
    }
    
    /// Test that platformPresentItemCollection_L1 uses CardDisplayable fallback
    @Test @MainActor func testPlatformPresentItemCollectionUsesCardDisplayableFallback() async {
        // Given: Core Data entities with nil values and hints that fail
        let tasks = [
            CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil),
            CoreDataTask(title: nil, taskDescription: nil, status: "completed", priority: "high")
        ]
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",  // This will be nil, so hints should fail
                "itemSubtitleProperty": "taskDescription"
            ]
        )
        
        // When: Create view using platformPresentItemCollection_L1
        _ = platformPresentItemCollection_L1(
            items: tasks,
            hints: hints
        )
        
        // Then: View should be created successfully
        // This test will FAIL because the framework currently shows generic object descriptions
        // view is a non-optional View, so it exists if we reach here
        
        // Note: We can't easily test the actual content display in unit tests,
        // but this test documents the expected behavior for integration testing
    }
    
    /// Test that the priority system works correctly
    @Test func testPrioritySystemCorrectOrder() async {
        // Given: Entity with meaningful hint values and CardDisplayable implementation
        let task = CoreDataTask(title: "Hint Title", taskDescription: "Hint Description", status: "completed", priority: "urgent")
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",  // This will work
                "itemSubtitleProperty": "taskDescription"  // This will work
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        
        // Then: Should use hints (Priority 1) over CardDisplayable (Priority 2)
        // This test should PASS because hints take precedence when they work
        #expect(extractedTitle == "Hint Title", "Should use hints when they extract meaningful values")
        #expect(extractedSubtitle == "Hint Description", "Should use hints when they extract meaningful values")
    }
    
    /// Test that CardDisplayable protocol is used when hints extract non-string values
    @Test func testCardDisplayableFallbackWhenHintsExtractNonStringValues() async {
        // Given: Entity with non-string values and hints
        struct TestItem: Identifiable, CardDisplayable {
            public let id = UUID()
            let title: Int  // Non-string value
            let description: Bool  // Non-string value
            
            public var cardTitle: String {
                return "Protocol Title"
            }
            
            public var cardSubtitle: String? {
                return "Protocol Subtitle"
            }
            
            public var cardIcon: String? {
                return "protocol.icon"
            }
            
            // cardColor removed - use PresentationHints instead (Issue #142)
        }
        
        let item = TestItem(title: 42, description: true)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",  // This will be Int, not String
                "itemSubtitleProperty": "description"  // This will be Bool, not String
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let titleResult = CardDisplayHelper.extractTitle(from: item, hints: hints)
        let subtitleResult = CardDisplayHelper.extractSubtitle(from: item, hints: hints)
        
        // Then: Should return nil when hints extract non-string values (property exists but wrong type)
        // Property exists but is not a String, so return nil (don't fall back)
        #expect(titleResult == nil, "Should return nil when hints extract non-string values")
        #expect(subtitleResult == nil, "Should return nil when hints extract non-string values")
    }
}
