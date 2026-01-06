import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for PresentationHints color configuration (Issue #142)
/// 
/// BUSINESS PURPOSE: Ensure color configuration can be moved from CardDisplayable protocol
/// to PresentationHints, allowing models to be SwiftUI-free for Intent extensions
/// TESTING SCOPE: PresentationHints colorMapping, itemColorProvider, defaultColor
/// METHODOLOGY: Test color extraction using new PresentationHints color configuration
@Suite("Presentation Hints Color Configuration")
struct PresentationHintsColorConfigurationTests {
    
    // MARK: - Test Data Structures
    
    /// Simple test item that conforms to CardDisplayable (without cardColor)
    struct TestItem: Identifiable, CardDisplayable {
        let id = UUID()
        let title: String
        
        var cardTitle: String { title }
        var cardSubtitle: String? { nil }
        var cardDescription: String? { nil }
        var cardIcon: String? { "star.fill" }
        // cardColor removed - should use PresentationHints instead
    }
    
    /// Another test item type for type-based color mapping
    struct AnotherItem: Identifiable, CardDisplayable {
        let id = UUID()
        let title: String
        
        var cardTitle: String { title }
        var cardSubtitle: String? { nil }
        var cardDescription: String? { nil }
        var cardIcon: String? { "circle.fill" }
    }
    
    // MARK: - Color Mapping Tests
    
    @Test func testColorMappingByType() async {
        // Given: Items and hints with type-based color mapping
        let item1 = TestItem(title: "Item 1")
        let item2 = AnotherItem(title: "Item 2")
        let hints = PresentationHints(
            colorMapping: [
                ObjectIdentifier(TestItem.self): .blue,
                ObjectIdentifier(AnotherItem.self): .green
            ]
        )
        
        // When: Extract colors using CardDisplayHelper
        let color1 = CardDisplayHelper.extractColor(from: item1, hints: hints)
        let color2 = CardDisplayHelper.extractColor(from: item2, hints: hints)
        
        // Then: Should return colors from type-based mapping
        #expect(color1 == .blue, "Should return blue for TestItem from colorMapping")
        #expect(color2 == .green, "Should return green for AnotherItem from colorMapping")
    }
    
    @Test func testColorMappingTakesPrecedenceOverItemColorProvider() async {
        // Given: Hints with both colorMapping and itemColorProvider
        let item = TestItem(title: "Test")
        let hints = PresentationHints(
            colorMapping: [ObjectIdentifier(TestItem.self): .blue],
            itemColorProvider: { _ in .red }  // Should be ignored
        )
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should use colorMapping (higher priority)
        #expect(color == .blue, "colorMapping should take precedence over itemColorProvider")
    }
    
    @Test func testItemColorProviderWhenNoTypeMapping() async {
        // Given: Hints with itemColorProvider but no type mapping
        let item = TestItem(title: "Test")
        let hints = PresentationHints(
            itemColorProvider: { item in
                // Custom logic based on item properties
                item.cardTitle == "Test" ? .purple : .orange
            }
        )
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should use itemColorProvider
        #expect(color == .purple, "Should use itemColorProvider when no type mapping")
    }
    
    @Test func testItemColorProviderWithDifferentItems() async {
        // Given: Multiple items with itemColorProvider
        let item1 = TestItem(title: "First")
        let item2 = TestItem(title: "Second")
        let hints = PresentationHints(
            itemColorProvider: { item in
                item.cardTitle.contains("First") ? .cyan : .mint
            }
        )
        
        // When: Extract colors
        let color1 = CardDisplayHelper.extractColor(from: item1, hints: hints)
        let color2 = CardDisplayHelper.extractColor(from: item2, hints: hints)
        
        // Then: Should return different colors based on item properties
        #expect(color1 == .cyan, "Should return cyan for 'First' item")
        #expect(color2 == .mint, "Should return mint for 'Second' item")
    }
    
    @Test func testDefaultColorWhenNoMappingOrProvider() async {
        // Given: Hints with only defaultColor
        let item = TestItem(title: "Test")
        let hints = PresentationHints(
            defaultColor: .yellow
        )
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should use defaultColor
        #expect(color == .yellow, "Should use defaultColor when no mapping or provider")
    }
    
    @Test func testDefaultColorWhenProviderReturnsNil() async {
        // Given: Hints with itemColorProvider that returns nil and defaultColor
        let item = TestItem(title: "Test")
        let hints = PresentationHints(
            itemColorProvider: { _ in nil },
            defaultColor: .orange
        )
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should fall back to defaultColor
        #expect(color == .orange, "Should use defaultColor when provider returns nil")
    }
    
    @Test func testPriorityOrderColorMappingThenProviderThenDefault() async {
        // Given: Hints with all three color sources
        let item = TestItem(title: "Test")
        let hints = PresentationHints(
            colorMapping: [ObjectIdentifier(TestItem.self): .blue],
            itemColorProvider: { _ in .red },
            defaultColor: .yellow
        )
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should use colorMapping (highest priority)
        #expect(color == .blue, "Should prioritize colorMapping over provider and default")
    }
    
    @Test func testNoColorWhenAllSourcesAreNil() async {
        // Given: Hints with no color configuration
        let item = TestItem(title: "Test")
        let hints = PresentationHints()
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should return nil (no color configured)
        #expect(color == nil, "Should return nil when no color configuration provided")
    }
    
    @Test func testColorMappingWithMultipleTypes() async {
        // Given: Multiple item types with different colors
        let item1 = TestItem(title: "Test 1")
        let item2 = AnotherItem(title: "Test 2")
        let item3 = TestItem(title: "Test 3")
        let hints = PresentationHints(
            colorMapping: [
                ObjectIdentifier(TestItem.self): .blue,
                ObjectIdentifier(AnotherItem.self): .green
            ]
        )
        
        // When: Extract colors
        let color1 = CardDisplayHelper.extractColor(from: item1, hints: hints)
        let color2 = CardDisplayHelper.extractColor(from: item2, hints: hints)
        let color3 = CardDisplayHelper.extractColor(from: item3, hints: hints)
        
        // Then: Should return correct colors for each type
        #expect(color1 == .blue, "TestItem should return blue")
        #expect(color2 == .green, "AnotherItem should return green")
        #expect(color3 == .blue, "Another TestItem should also return blue")
    }
    
    @Test func testItemColorProviderCanAccessItemProperties() async {
        // Given: Item with properties and itemColorProvider that uses them
        struct ColoredItem: Identifiable, CardDisplayable {
            let id = UUID()
            let title: String
            let priority: String
            
            var cardTitle: String { title }
            var cardSubtitle: String? { priority }
        }
        
        let item = ColoredItem(title: "Urgent Task", priority: "high")
        let hints = PresentationHints(
            itemColorProvider: { item in
                // Use subtitle (priority) to determine color
                if item.cardSubtitle == "high" {
                    return .red
                }
                return .gray
            }
        )
        
        // When: Extract color
        let color = CardDisplayHelper.extractColor(from: item, hints: hints)
        
        // Then: Should use item properties to determine color
        #expect(color == .red, "Should return red for high priority item")
    }
}

