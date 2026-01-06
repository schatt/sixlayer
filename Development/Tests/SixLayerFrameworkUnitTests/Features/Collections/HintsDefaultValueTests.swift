import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for hints default value feature
/// All features are implemented and tests are passing
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Hints Default Value")
struct HintsDefaultValueTests {
    
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
            return title ?? "Untitled Task"
        }
        
        public var cardSubtitle: String? {
            return status
        }
        
        public var cardIcon: String? {
            switch status {
            case "completed": return "checkmark.circle.fill"
            case "in_progress": return "clock.fill"
            default: return "doc.text"
            }
        }
        
        // cardColor removed - use PresentationHints instead (Issue #142)
    }
    
    // MARK: - Default Value Tests
    
    /// Test that hints can specify default values for nil properties
    @Test func testHintsWithDefaultValuesForNilProperties() async {
        // Given: Core Data entity with nil values and hints with default values
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",
                "itemTitleDefault": "Default Task Title",  // New default value support
                "itemSubtitleProperty": "taskDescription",
                "itemSubtitleDefault": "Default Description",
                "itemIconProperty": "status",
                "itemIconDefault": "default.icon",
                "itemColorProperty": "priority",
                "itemColorDefault": "blue"  // Color as string
            ]
        )
        
        // When: Extract properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        let extractedIcon = CardDisplayHelper.extractIcon(from: task, hints: hints)
        let extractedColor = CardDisplayHelper.extractColor(from: task, hints: hints)
        
        // Then: Should use default values when properties are nil
        // This test will FAIL because the framework doesn't support default values yet
        #expect(extractedTitle == "Default Task Title", "Should use default value when property is nil")
        #expect(extractedSubtitle == "Default Description", "Should use default value when property is nil")
        #expect(extractedIcon == "default.icon", "Should use default value when property is nil")
        #expect(extractedColor == .blue, "Should use default value when property is nil")
    }
    
    /// Test that hints can specify default values for empty string properties
    @Test func testHintsWithDefaultValuesForEmptyStringProperties() async {
        // Given: Entity with empty string values and hints with default values
        let task = CoreDataTask(title: "", taskDescription: "", status: "", priority: "")
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",
                "itemTitleDefault": "Default Task Title",
                "itemSubtitleProperty": "taskDescription",
                "itemSubtitleDefault": "Default Description"
            ]
        )
        
        // When: Extract properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        
        // Then: Should use default values when properties are empty strings
        #expect(extractedTitle == "Default Task Title", "Should use default value when property is empty string")
        #expect(extractedSubtitle == "Default Description", "Should use default value when property is empty string")
    }
    
    /// Test that hints can specify default values for invalid property names
    @Test func testHintsWithDefaultValuesForInvalidPropertyNames() async {
        // Given: Entity with nil values and hints with invalid property names but default values
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "nonexistentProperty",
                "itemTitleDefault": "Default Task Title",
                "itemSubtitleProperty": "anotherNonexistentProperty",
                "itemSubtitleDefault": "Default Description"
            ]
        )
        
        // When: Extract properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        
        // Then: Should use default values when property names are invalid
        #expect(extractedTitle == "Default Task Title", "Should use default value when property name is invalid")
        #expect(extractedSubtitle == "Default Description", "Should use default value when property name is invalid")
    }
    
    /// Test that hints with default values take precedence over CardDisplayable protocol
    @Test @MainActor func testHintsDefaultValuesTakePrecedenceOverCardDisplayable() async {
        // Given: Entity with nil values, CardDisplayable implementation, and hints with default values
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",
                "itemTitleDefault": "Hint Default Title",  // This should take precedence
                "itemSubtitleProperty": "taskDescription",
                "itemSubtitleDefault": "Hint Default Subtitle"
            ]
        )
        
        // When: Extract properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        
        // Then: Should use hint default values over CardDisplayable protocol
        #expect(extractedTitle == "Hint Default Title", "Should use hint default value over CardDisplayable protocol")
        #expect(extractedSubtitle == "Hint Default Subtitle", "Should use hint default value over CardDisplayable protocol")
    }
    
    /// Test that hints with default values work with non-string properties
    @Test @MainActor func testHintsWithDefaultValuesForNonStringProperties() async {
        // Given: Entity with non-string values and hints with default values
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
                "itemTitleDefault": "Default Title",
                "itemSubtitleProperty": "description",  // This will be Bool, not String
                "itemSubtitleDefault": "Default Subtitle"
            ]
        )
        
        // When: Extract properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: item, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: item, hints: hints)
        
        // Then: Should use default values when properties are non-string
        #expect(extractedTitle == "Default Title", "Should use default value when property is non-string")
        #expect(extractedSubtitle == "Default Subtitle", "Should use default value when property is non-string")
    }
    
    /// Test that hints with default values work with color properties
    @Test @MainActor func testHintsWithDefaultValuesForColorProperties() async {
        // Given: Entity with nil color values and hints with default color values
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemColorProperty": "priority",
                "itemColorDefault": "red"  // Color as string
            ]
        )
        
        // When: Extract color using CardDisplayHelper
        let extractedColor = CardDisplayHelper.extractColor(from: task, hints: hints)
        
        // Then: Should use default color value when property is nil
        #expect(extractedColor == .red, "Should use default color value when property is nil")
    }
    
    /// Test that hints with default values work with mixed scenarios
    @Test @MainActor func testHintsWithDefaultValuesMixedScenarios() async {
        // Given: Entity with mixed nil and valid values, and hints with default values
        let task = CoreDataTask(title: "Valid Title", taskDescription: nil, status: "completed", priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",
                "itemTitleDefault": "Default Title",  // Should not be used since title is valid
                "itemSubtitleProperty": "taskDescription",
                "itemSubtitleDefault": "Default Subtitle",  // Should be used since taskDescription is nil
                "itemIconProperty": "status",
                "itemIconDefault": "default.icon",  // Should not be used since status is valid
                "itemColorProperty": "priority",
                "itemColorDefault": "blue"  // Should be used since priority is nil
            ]
        )
        
        // When: Extract properties using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: task, hints: hints)
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: task, hints: hints)
        let extractedIcon = CardDisplayHelper.extractIcon(from: task, hints: hints)
        let extractedColor = CardDisplayHelper.extractColor(from: task, hints: hints)
        
        // Then: Should use actual values when available, default values when nil
        #expect(extractedTitle == "Valid Title", "Should use actual value when available")
        #expect(extractedSubtitle == "Default Subtitle", "Should use default value when property is nil")
        #expect(extractedIcon == "completed", "Should use actual value when available")
        #expect(extractedColor == .blue, "Should use default value when property is nil")
    }
    
    /// Test that hints with default values work with platformPresentItemCollection_L1
    @Test @MainActor func testPlatformPresentItemCollectionWithDefaultValues() async {
        // Given: Core Data entities with nil values and hints with default values
        let tasks = [
            CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil),
            CoreDataTask(title: "Valid Title", taskDescription: nil, status: "completed", priority: nil)
        ]
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",
                "itemTitleDefault": "Default Task Title",
                "itemSubtitleProperty": "taskDescription",
                "itemSubtitleDefault": "Default Description"
            ]
        )
        
        // When: Create view using platformPresentItemCollection_L1
        _ = platformPresentItemCollection_L1(
            items: tasks,
            hints: hints
        )
        
        // Then: View should be created successfully
        
        // Note: We can't easily test the actual content display in unit tests,
        // but this test documents the expected behavior for integration testing
    }
    
    /// Test that hints with default values work with color string parsing
    @Test func testHintsWithDefaultValuesColorStringParsing() async {
        // Given: Entity with nil color values and hints with various color string formats
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemColorProperty": "priority",
                "itemColorDefault": "red"  // Should parse to Color.red
            ]
        )
        
        // When: Extract color using CardDisplayHelper
        let extractedColor = CardDisplayHelper.extractColor(from: task, hints: hints)
        
        // Then: Should parse color string to Color
        #expect(extractedColor == .red, "Should parse color string to Color.red")
    }
    
    /// Test that hints with default values work with icon string parsing
    @Test func testHintsWithDefaultValuesIconStringParsing() async {
        // Given: Entity with nil icon values and hints with icon string
        let task = CoreDataTask(title: nil, taskDescription: nil, status: nil, priority: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemIconProperty": "status",
                "itemIconDefault": "star.fill"  // Should use as icon string
            ]
        )
        
        // When: Extract icon using CardDisplayHelper
        let extractedIcon = CardDisplayHelper.extractIcon(from: task, hints: hints)
        
        // Then: Should use icon string as-is
        // This test will FAIL because the framework doesn't support default values yet
        #expect(extractedIcon == "star.fill", "Should use icon string as-is")
    }
}
