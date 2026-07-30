//
//  FieldLayoutPackerTests.swift
//  SixLayerFrameworkTests
//
//  Shared field packing for framework-owned layouts (GitHub #385).
//

import Testing
import CoreGraphics
@testable import SixLayerFramework

@Suite("Field Layout Packer")
struct FieldLayoutPackerTests {

    private func item(
        id: String,
        kind: FieldLayoutPackKind,
        preferredWidth: CGFloat?
    ) -> FieldLayoutPackItem {
        FieldLayoutPackItem(id: id, kind: kind, preferredWidth: preferredWidth)
    }

    @Test func pack_preservesAuthorOrderAcrossRows() {
        let items = [
            item(id: "a", kind: .compact, preferredWidth: 100),
            item(id: "b", kind: .compact, preferredWidth: 100),
            item(id: "c", kind: .compact, preferredWidth: 100)
        ]
        let rows = FieldLayoutPacker.pack(items, availableWidth: 250, spacing: 10, maxItemsPerRow: 4)
        #expect(rows.map { $0.map(\.id) } == [["a", "b"], ["c"]])
    }

    @Test func pack_keepsSameTypeRunTogether_doesNotOrphanCheckOntoNote() {
        // check, check, check, note — must not become [check,check] / [check,note]
        let items = [
            item(id: "c1", kind: .checkbox, preferredWidth: 80),
            item(id: "c2", kind: .checkbox, preferredWidth: 80),
            item(id: "c3", kind: .checkbox, preferredWidth: 80),
            item(id: "note", kind: .tall, preferredWidth: 300)
        ]
        let rows = FieldLayoutPacker.pack(items, availableWidth: 200, spacing: 10, maxItemsPerRow: 4)
        #expect(rows.map { $0.map(\.id) } == [["c1", "c2"], ["c3"], ["note"]])
        #expect(!rows.contains { row in
            row.map(\.id).contains("c3") && row.map(\.id).contains("note")
        })
    }

    @Test func pack_placesFullCheckboxRunOnOneRowWhenWidthAllows() {
        let items = [
            item(id: "c1", kind: .checkbox, preferredWidth: 60),
            item(id: "c2", kind: .checkbox, preferredWidth: 60),
            item(id: "c3", kind: .checkbox, preferredWidth: 60),
            item(id: "note", kind: .tall, preferredWidth: nil)
        ]
        let rows = FieldLayoutPacker.pack(items, availableWidth: 220, spacing: 10, maxItemsPerRow: 4)
        #expect(rows.map { $0.map(\.id) } == [["c1", "c2", "c3"], ["note"]])
    }

    @Test func pack_isolatesTallFieldsOnOwnRow() {
        let items = [
            item(id: "name", kind: .compact, preferredWidth: 120),
            item(id: "notes", kind: .tall, preferredWidth: 200),
            item(id: "city", kind: .compact, preferredWidth: 120)
        ]
        let rows = FieldLayoutPacker.pack(items, availableWidth: 400, spacing: 10, maxItemsPerRow: 4)
        #expect(rows.map { $0.map(\.id) } == [["name"], ["notes"], ["city"]])
    }

    @Test func pack_doesNotMixWideFlexWithCompactStrip() {
        let items = [
            item(id: "c1", kind: .checkbox, preferredWidth: 50),
            item(id: "note", kind: .wideFlex, preferredWidth: nil)
        ]
        let rows = FieldLayoutPacker.pack(items, availableWidth: 400, spacing: 10, maxItemsPerRow: 4)
        #expect(rows.map { $0.map(\.id) } == [["c1"], ["note"]])
    }

    @Test func pack_respectsMaxItemsPerRow() {
        let items = (1...5).map { item(id: "c\($0)", kind: .checkbox, preferredWidth: 40) }
        let rows = FieldLayoutPacker.pack(items, availableWidth: 1000, spacing: 10, maxItemsPerRow: 3)
        #expect(rows.map { $0.map(\.id) } == [["c1", "c2", "c3"], ["c4", "c5"]])
    }

    @Test func pack_nilPreferredWidthUsesFlexibleShare() {
        // Flexible items still participate; alone they take a row.
        let items = [
            item(id: "flex", kind: .compact, preferredWidth: nil)
        ]
        let rows = FieldLayoutPacker.pack(items, availableWidth: 300, spacing: 10, maxItemsPerRow: 4)
        #expect(rows.map { $0.map(\.id) } == [["flex"]])
    }
}
