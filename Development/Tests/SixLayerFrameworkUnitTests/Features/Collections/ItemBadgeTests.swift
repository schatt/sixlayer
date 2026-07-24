//
//  ItemBadgeTests.swift
//  SixLayerFrameworkTests
//
//  Tests for ItemBadge component
//  Issue #144 - Color Resolution System from Hints Files
//  Issue #219 - hostability smoke instead of Bool(true) no-ops
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Item Badge Component", HostedViewTestIsolationTrait())
struct ItemBadgeTests {
    
    struct TestCategory: Identifiable, CardDisplayable {
        let id = UUID()
        let name: String
        let icon: String?
        let color: String?
        
        var cardTitle: String { name }
        var cardSubtitle: String? { nil }
        var cardDescription: String? { nil }
        var cardIcon: String? { icon }
    }
    
    #if canImport(SwiftUI)
    @Test @MainActor func testItemBadgeDefaultStyle() async throws {
        let hints = PresentationHints(
            itemColorProvider: { item in
                if let category = item as? TestCategory, category.color == "blue" {
                    return .blue
                }
                return nil
            }
        )
        let category = TestCategory(name: "Work", icon: "briefcase.fill", color: "blue")
        let badge = ItemBadge(
            item: category,
            icon: category.icon,
            text: category.name,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(badge))
    }
    
    @Test @MainActor func testItemBadgeOutlineStyle() async throws {
        let hints = PresentationHints(
            itemColorProvider: { item in
                if item is TestCategory {
                    return .green
                }
                return nil
            }
        )
        let category = TestCategory(name: "Personal", icon: "person.fill", color: "green")
        let badge = ItemBadge(
            item: category,
            icon: category.icon,
            text: category.name,
            style: .outline,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(badge))
    }
    
    @Test @MainActor func testItemBadgeSubtleStyle() async throws {
        let hints = PresentationHints(
            itemColorProvider: { item in
                if item is TestCategory {
                    return .orange
                }
                return nil
            }
        )
        let category = TestCategory(name: "Shopping", icon: "cart.fill", color: "orange")
        let badge = ItemBadge(
            item: category,
            icon: category.icon,
            text: category.name,
            style: .subtle,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(badge))
    }
    
    @Test @MainActor func testItemBadgeIconOnlyStyle() async throws {
        let hints = PresentationHints(
            itemColorProvider: { item in
                if item is TestCategory {
                    return .purple
                }
                return nil
            }
        )
        let category = TestCategory(name: "Travel", icon: "airplane", color: "purple")
        let badge = ItemBadge(
            item: category,
            icon: category.icon,
            style: .iconOnly,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(badge))
    }
    
    @Test @MainActor func testItemBadgeUsesColorFromHints() async throws {
        let hints = PresentationHints(
            itemColorProvider: { item in
                if let category = item as? TestCategory, category.color == "red" {
                    return .red
                }
                return nil
            }
        )
        let category = TestCategory(name: "Urgent", icon: "exclamationmark.triangle.fill", color: "red")
        let badge = ItemBadge(
            item: category,
            icon: category.icon,
            text: category.name,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(badge))
    }
    
    @Test @MainActor func testItemBadgeFallsBackToDefaultColor() async throws {
        let hints = PresentationHints(
            defaultColor: .gray
        )
        let category = TestCategory(name: "Unknown", icon: "questionmark", color: nil)
        let badge = ItemBadge(
            item: category,
            icon: category.icon,
            text: category.name,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(badge))
    }
    #endif
}
