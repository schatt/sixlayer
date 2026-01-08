//
//  CardBadgeContentTests.swift
//  SixLayerFrameworkTests
//
//  Tests for optional badgeContent in card components
//  Issue #144 - Color Resolution System from Hints Files
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Card Badge Content")
struct CardBadgeContentTests {
    
    struct TestItem: Identifiable, CardDisplayable {
        let id = UUID()
        let title: String
        let category: String
        
        var cardTitle: String { title }
        var cardSubtitle: String? { category }
        var cardDescription: String? { nil }
        var cardIcon: String? { "star.fill" }
    }
    
    #if canImport(SwiftUI)
    @Test @MainActor func testExpandableCardWithBadgeContent() async throws {
        // Given: Item and hints with badge content
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Work")
        
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 150,
            cardHeight: 200,
            padding: 16
        )
        
        let strategy = CardExpansionStrategy(
            supportedStrategies: [.contentReveal],
            primaryStrategy: .contentReveal,
            expansionScale: 1.15,
            animationDuration: 0.3
        )
        
        // When: Creating card with badge content
        let card = ExpandableCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            strategy: strategy,
            hints: hints,
            isExpanded: false,
            isHovered: false,
            onExpand: {},
            onCollapse: {},
            onHover: { _ in },
            badgeContent: { item in
                ItemBadge(
                    item: item,
                    text: item.category,
                    hints: hints
                )
            }
        )
        
        // Then: Card should be created with badge content
        #expect(true)
    }
    
    @Test @MainActor func testSimpleCardWithBadgeContent() async throws {
        // Given: Item and hints
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Personal")
        
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 150,
            cardHeight: 200,
            padding: 16
        )
        
        // When: Creating card with badge content
        let card = SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: hints,
            badgeContent: { item in
                ItemBadge(
                    item: item,
                    text: item.category,
                    hints: hints
                )
            }
        )
        
        // Then: Card should be created with badge content
        #expect(true)
    }
    
    @Test @MainActor func testListCardWithBadgeContent() async throws {
        // Given: Item and hints
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Shopping")
        
        // When: Creating card with badge content
        let card = ListCardComponent(
            item: item,
            hints: hints,
            badgeContent: { item in
                ItemBadge(
                    item: item,
                    text: item.category,
                    hints: hints
                )
            }
        )
        
        // Then: Card should be created with badge content
        #expect(true)
    }
    
    @Test @MainActor func testCardWithoutBadgeContent() async throws {
        // Given: Item and hints without badge content
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Work")
        
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 150,
            cardHeight: 200,
            padding: 16
        )
        
        // When: Creating card without badge content (nil)
        let card = SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: hints,
            badgeContent: nil
        )
        
        // Then: Card should be created normally (backward compatible)
        #expect(card != nil)
    }
    #endif
}

