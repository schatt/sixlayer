import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for CardDisplayHelper returning nil instead of hardcoded fallbacks
/// All features are implemented and tests are passing
@Suite("Card Display Helper Nil Fallback")
struct CardDisplayHelperNilFallbackTests {
    
    /// Mock entity for testing
    struct TestEntity: Identifiable {
        public let id = UUID()
        let title: String?
        let subtitle: String?
        let description: String?
        
        init(title: String? = nil, subtitle: String? = nil, description: String? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.description = description
        }
    }
    
    /// Test that extractTitle returns nil when no meaningful content is found
    @Test func testExtractTitleReturnsNilWhenNoContent() async {
        // Given: Entity with nil values and no hints
        let entity = TestEntity(title: nil, subtitle: nil, description: nil)
        
        // When: Extract title using CardDisplayHelper
        let result = CardDisplayHelper.extractTitle(from: entity, hints: nil)
        
        // Then: Should return nil instead of hardcoded "Untitled"
        #expect(result == nil, "Should return nil when no meaningful content is found")
    }
    
    /// Test that extractTitle returns nil when hints fail and no default
    @Test func testExtractTitleReturnsNilWhenHintsFailNoDefault() async {
        // Given: Entity with nil values and hints that fail
        let entity = TestEntity(title: nil, subtitle: nil, description: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "nonexistentProperty"  // Property doesn't exist
                // No default provided
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let result = CardDisplayHelper.extractTitle(from: entity, hints: hints)
        
        // Then: Should return nil instead of hardcoded fallback
        #expect(result == nil, "Should return nil when hints fail and no default provided")
    }
    
    /// Test that extractTitle returns nil when hints extract empty string and no default
    @Test func testExtractTitleReturnsNilWhenEmptyStringNoDefault() async {
        // Given: Entity with empty string values and hints with no default
        let entity = TestEntity(title: "", subtitle: "", description: "")
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title"  // Will extract empty string
                // No default provided
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let result = CardDisplayHelper.extractTitle(from: entity, hints: hints)
        
        // Then: Should return nil instead of hardcoded fallback
        #expect(result == nil, "Should return nil when empty string and no default provided")
    }
    
    /// Test that extractSubtitle returns nil when no meaningful content
    @Test func testExtractSubtitleReturnsNilWhenNoContent() async {
        // Given: Entity with nil values and no hints
        let entity = TestEntity(title: nil, subtitle: nil, description: nil)
        
        // When: Extract subtitle using CardDisplayHelper
        let result = CardDisplayHelper.extractSubtitle(from: entity, hints: nil)
        
        // Then: Should return nil instead of hardcoded fallback
        #expect(result == nil, "Should return nil when no meaningful content is found")
    }
    
    /// Test that extractIcon returns nil when no meaningful content
    @Test func testExtractIconReturnsNilWhenNoContent() async {
        // Given: Entity with nil values and no hints
        let entity = TestEntity(title: nil, subtitle: nil, description: nil)
        
        // When: Extract icon using CardDisplayHelper
        let result = CardDisplayHelper.extractIcon(from: entity, hints: nil)
        
        // Then: Should return nil instead of hardcoded "star.fill"
        #expect(result == nil, "Should return nil when no meaningful content is found")
    }
    
    /// Test that extractColor returns nil when no meaningful content
    @Test func testExtractColorReturnsNilWhenNoContent() async {
        // Given: Entity with nil values and no hints
        let entity = TestEntity(title: nil, subtitle: nil, description: nil)
        
        // When: Extract color using CardDisplayHelper
        let result = CardDisplayHelper.extractColor(from: entity, hints: nil)
        
        // Then: Should return nil instead of hardcoded .blue
        #expect(result == nil, "Should return nil when no meaningful content is found")
    }
    
    /// Test that meaningful content is still returned correctly
    @Test func testExtractTitleReturnsMeaningfulContent() async {
        // Given: Entity with meaningful content
        let entity = TestEntity(title: "Real Title", subtitle: "Real Subtitle", description: "Real Description")
        
        // When: Extract title using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: entity, hints: nil)
        
        // Then: Should return the actual content
        // This test should PASS - meaningful content should still be returned
        #expect(extractedTitle == "Real Title", "Should return meaningful content when available")
    }
    
    /// Test that default values are still used when configured
    @Test func testExtractTitleUsesDefaultWhenConfigured() async {
        // Given: Entity with empty content but default configured
        let entity = TestEntity(title: "", subtitle: "", description: "")
        let hints = PresentationHints(
            customPreferences: [
                "itemTitleProperty": "title",
                "itemTitleDefault": "Default Title"
            ]
        )
        
        // When: Extract title using CardDisplayHelper
        let extractedTitle = CardDisplayHelper.extractTitle(from: entity, hints: hints)
        
        // Then: Should use the configured default
        // This test should PASS - defaults should still work
        #expect(extractedTitle == "Default Title", "Should use configured default when available")
    }
    
    /// Test that extractSubtitle returns meaningful content when available
    @Test func testExtractSubtitleReturnsMeaningfulContent() async {
        // Given: Entity with meaningful subtitle
        let entity = TestEntity(title: "Title", subtitle: "Real Subtitle", description: "Description")
        
        // When: Extract subtitle using CardDisplayHelper
        let extractedSubtitle = CardDisplayHelper.extractSubtitle(from: entity, hints: nil)
        
        // Then: Should return the actual content
        #expect(extractedSubtitle == "Real Subtitle", "Should return meaningful subtitle when available")
    }
    
    /// Test that extractIcon returns meaningful content when available
    @Test func testExtractIconReturnsMeaningfulContent() async {
        // Given: Entity with meaningful icon property (via hints)
        let entity = TestEntity(title: "Title", subtitle: nil, description: nil)
        let hints = PresentationHints(
            customPreferences: [
                "itemIconProperty": "title"  // Use title as icon for testing
            ]
        )
        
        // When: Extract icon using CardDisplayHelper
        let extractedIcon = CardDisplayHelper.extractIcon(from: entity, hints: hints)
        
        // Then: Should return the actual content
        #expect(extractedIcon == "Title", "Should return meaningful icon when available")
    }
    
    /// Test that extractColor returns meaningful content when available via PresentationHints
    @Test func testExtractColorReturnsMeaningfulContent() async {
        // Given: Entity that conforms to CardDisplayable and hints with color configuration
        struct ColoredEntity: CardDisplayable {
            let cardTitle: String = "Test"
            // cardColor removed - use PresentationHints instead (Issue #142)
        }
        let entity = ColoredEntity()
        let hints = PresentationHints(
            itemColorProvider: { _ in .red }
        )
        
        // When: Extract color using CardDisplayHelper
        let extractedColor = CardDisplayHelper.extractColor(from: entity, hints: hints)
        
        // Then: Should return the color from PresentationHints
        #expect(extractedColor == .red, "Should return meaningful color from PresentationHints")
    }
}
