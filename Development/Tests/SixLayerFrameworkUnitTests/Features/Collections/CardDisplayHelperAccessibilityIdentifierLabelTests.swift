import Foundation
import Testing
@testable import SixLayerFramework

/// Issue #244: `PresentationHints.customPreferences` can steer which property feeds automatic row accessibility identifier segments, with title resolution as the default.
@Suite("CardDisplayHelper accessibility identifier segment")
struct CardDisplayHelperAccessibilityIdentifierSegmentTests {

    private struct CatalogRow: Identifiable {
        let id: String
        let title: String
        let sku: String
    }

    @Test func accessibilityIdentifierSegment_usesHintPropertyWhenConfigured() {
        let row = CatalogRow(id: "a", title: "Widget", sku: "INV-42")
        let hints = PresentationHints(customPreferences: [
            "itemAccessibilityIdentifierProperty": "sku"
        ])
        #expect(CardDisplayHelper.accessibilityIdentifierSegment(from: row, hints: hints) == "INV-42")
    }

    @Test func accessibilityIdentifierSegment_defaultsToTitleResolutionWhenHintAbsent() {
        let row = CatalogRow(id: "a", title: "Widget", sku: "INV-9")
        let hints = PresentationHints(customPreferences: ["itemTitleProperty": "title"])
        #expect(CardDisplayHelper.accessibilityIdentifierSegment(from: row, hints: hints) == "Widget")
    }

    @Test func accessibilityIdentifierSegment_usesDefaultWhenPropertyMissing() {
        let row = CatalogRow(id: "a", title: "Widget", sku: "INV-1")
        let hints = PresentationHints(customPreferences: [
            "itemAccessibilityIdentifierProperty": "missingProperty",
            "itemAccessibilityIdentifierDefault": "FALLBACK-ID"
        ])
        #expect(CardDisplayHelper.accessibilityIdentifierSegment(from: row, hints: hints) == "FALLBACK-ID")
    }

    @Test func accessibilityIdentifierLabel_appendsStableId() {
        let row = CatalogRow(id: "row-1", title: "Widget", sku: "SKU-A")
        let hints = PresentationHints(customPreferences: [
            "itemAccessibilityIdentifierProperty": "sku"
        ])
        let label = CardDisplayHelper.accessibilityIdentifierLabel(for: row, hints: hints)
        #expect(label.contains("SKU-A"))
        #expect(label.contains("row-1"))
    }
}
