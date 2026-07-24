//
//  CardBadgeContentTests.swift
//  SixLayerFrameworkTests
//
//  Tests for optional badgeContent in card components
//  Issue #144 - Color Resolution System from Hints Files
//  Issue #219 - hostability smoke instead of #expect(true) no-ops
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Card Badge Content", HostedViewTestIsolationTrait())
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
        
        #expect(PlatformContainerStructureAssertions.isHostable(card))
    }
    
    @Test @MainActor func testSimpleCardWithBadgeContent() async throws {
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Personal")
        
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 150,
            cardHeight: 200,
            padding: 16
        )
        
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
        
        #expect(PlatformContainerStructureAssertions.isHostable(card))
    }
    
    @Test @MainActor func testListCardWithBadgeContent() async throws {
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Shopping")
        
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
        
        #expect(PlatformContainerStructureAssertions.isHostable(card))
    }
    
    @Test @MainActor func testCardWithoutBadgeContent() async throws {
        let hints = PresentationHints()
        let item = TestItem(title: "Test Item", category: "Work")
        
        let layoutDecision = IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 150,
            cardHeight: 200,
            padding: 16
        )
        
        let card = SimpleCardComponent(
            item: item,
            layoutDecision: layoutDecision,
            hints: hints,
            badgeContent: nil
        )
        
        #expect(PlatformContainerStructureAssertions.isHostable(card))
    }
    #endif
}
