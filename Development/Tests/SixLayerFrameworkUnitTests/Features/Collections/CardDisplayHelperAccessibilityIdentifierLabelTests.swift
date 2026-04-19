import Foundation
import Testing
@testable import SixLayerFramework

/// Issue #244: Row `identifierLabel` coalesces ``CardDisplayHelper.extractTitle`` with optional accessibility-property hints and ``accessibilityStableIdentityToken``.
@Suite("CardDisplayHelper accessibility identifier label")
struct CardDisplayHelperAccessibilityIdentifierLabelTests {

    private struct CatalogRow: Identifiable {
        let id: String
        let title: String
        let sku: String
    }

    @Test func accessibilityIdentifierLabel_prefersHintPropertyWhenConfigured() {
        let row = CatalogRow(id: "a", title: "Widget", sku: "INV-42")
        let hints = PresentationHints(customPreferences: [
            "itemAccessibilityIdentifierProperty": "sku"
        ])
        let label = CardDisplayHelper.accessibilityIdentifierLabel(for: row, hints: hints)
        #expect(label == "INV-42 a")
    }

    @Test func accessibilityIdentifierLabel_usesExtractTitleWhenHintAbsent() {
        let row = CatalogRow(id: "a", title: "Widget", sku: "INV-9")
        let hints = PresentationHints(customPreferences: ["itemTitleProperty": "title"])
        let label = CardDisplayHelper.accessibilityIdentifierLabel(for: row, hints: hints)
        #expect(label == "Widget a")
    }

    @Test func accessibilityIdentifierLabel_usesDefaultWhenHintPropertyMissing() {
        let row = CatalogRow(id: "a", title: "Widget", sku: "INV-1")
        let hints = PresentationHints(customPreferences: [
            "itemAccessibilityIdentifierProperty": "missingProperty",
            "itemAccessibilityIdentifierDefault": "FALLBACK-ID"
        ])
        let label = CardDisplayHelper.accessibilityIdentifierLabel(for: row, hints: hints)
        #expect(label == "FALLBACK-ID a")
    }

    @Test func accessibilityIdentifierLabel_pairsPrimaryWithStableIdentityToken() {
        let row = CatalogRow(id: "row-1", title: "Widget", sku: "SKU-A")
        let hints = PresentationHints(customPreferences: [
            "itemAccessibilityIdentifierProperty": "sku"
        ])
        let label = CardDisplayHelper.accessibilityIdentifierLabel(for: row, hints: hints)
        #expect(label == "SKU-A row-1")
    }

    @Test func accessibilityStableIdentityToken_matchesStringDescribingId() {
        let row = CatalogRow(id: "row-1", title: "T", sku: "S")
        #expect(CardDisplayHelper.accessibilityStableIdentityToken(for: row) == "row-1")
    }
}
