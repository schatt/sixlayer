//
//  ItemIconTests.swift
//  SixLayerFrameworkTests
//
//  Tests for ItemIcon component
//  Issue #144 - Color Resolution System from Hints Files
//  Issue #219 - hostability smoke instead of Bool(true) no-ops
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Item Icon Component", HostedViewTestIsolationTrait())
struct ItemIconTests {
    
    struct TestDocument: Identifiable, CardDisplayable {
        let id = UUID()
        let name: String
        let iconName: String
        let fileExtension: String
        
        var cardTitle: String { name }
        var cardSubtitle: String? { nil }
        var cardDescription: String? { nil }
        var cardIcon: String? { iconName }
    }
    
    #if canImport(SwiftUI)
    @Test @MainActor func testItemIconUsesColorFromHints() async throws {
        let hints = PresentationHints(
            itemColorProvider: { item in
                if let doc = item as? TestDocument {
                    switch doc.fileExtension.lowercased() {
                    case "pdf": return .red
                    case "jpg", "png": return .blue
                    case "doc": return .blue
                    default: return .gray
                    }
                }
                return nil
            }
        )
        let pdfDoc = TestDocument(name: "Report.pdf", iconName: "doc.fill", fileExtension: "pdf")
        let icon = ItemIcon(
            item: pdfDoc,
            iconName: pdfDoc.iconName,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(icon))
    }
    
    @Test @MainActor func testItemIconDefaultSize() async throws {
        let hints = PresentationHints(defaultColor: .blue)
        let doc = TestDocument(name: "Document.pdf", iconName: "doc.fill", fileExtension: "pdf")
        let icon = ItemIcon(
            item: doc,
            iconName: doc.iconName,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(icon))
    }
    
    @Test @MainActor func testItemIconCustomSize() async throws {
        let hints = PresentationHints(defaultColor: .green)
        let doc = TestDocument(name: "Image.jpg", iconName: "photo.fill", fileExtension: "jpg")
        let icon = ItemIcon(
            item: doc,
            iconName: doc.iconName,
            size: 32,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(icon))
    }
    
    @Test @MainActor func testItemIconFallsBackToDefaultColor() async throws {
        let hints = PresentationHints(defaultColor: .gray)
        let doc = TestDocument(name: "File.unknown", iconName: "doc.fill", fileExtension: "unknown")
        let icon = ItemIcon(
            item: doc,
            iconName: doc.iconName,
            hints: hints
        )
        #expect(PlatformContainerStructureAssertions.isHostable(icon))
    }
    #endif
}
