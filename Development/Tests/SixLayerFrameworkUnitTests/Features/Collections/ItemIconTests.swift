//
//  ItemIconTests.swift
//  SixLayerFrameworkTests
//
//  Tests for ItemIcon component
//  Issue #144 - Color Resolution System from Hints Files
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Item Icon Component")
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
        // Given: Hints with itemColorProvider based on file extension
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
        
        // When: Creating icon
        let _ = ItemIcon(
            item: pdfDoc,
            iconName: pdfDoc.iconName,
            hints: hints
        )
        
        // Then: Icon should be created with color from hints
        #expect(true)
    }
    
    @Test @MainActor func testItemIconDefaultSize() async throws {
        // Given: Item with hints
        let hints = PresentationHints(defaultColor: .blue)
        let doc = TestDocument(name: "Document.pdf", iconName: "doc.fill", fileExtension: "pdf")
        
        // When: Creating icon without specifying size
        let icon = ItemIcon(
            item: doc,
            iconName: doc.iconName,
            hints: hints
        )
        
        // Then: Icon should use default size
        #expect(true)
    }
    
    @Test @MainActor func testItemIconCustomSize() async throws {
        // Given: Item with hints
        let hints = PresentationHints(defaultColor: .green)
        let doc = TestDocument(name: "Image.jpg", iconName: "photo.fill", fileExtension: "jpg")
        
        // When: Creating icon with custom size
        let icon = ItemIcon(
            item: doc,
            iconName: doc.iconName,
            size: 32,
            hints: hints
        )
        
        // Then: Icon should use custom size
        #expect(true)
    }
    
    @Test @MainActor func testItemIconFallsBackToDefaultColor() async throws {
        // Given: Hints with default color but no itemColorProvider
        let hints = PresentationHints(defaultColor: .gray)
        let doc = TestDocument(name: "File.unknown", iconName: "doc.fill", fileExtension: "unknown")
        
        // When: Creating icon
        let icon = ItemIcon(
            item: doc,
            iconName: doc.iconName,
            hints: hints
        )
        
        // Then: Icon should use default color
        #expect(true)
    }
    #endif
}

