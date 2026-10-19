//
//  HintsDrivenCatalogContainerInsetTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #559: catalog list/grid stacks pad with collectionContentInset.
//

import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

@Suite("Hints-driven catalog content inset (#559)", HostedViewTestIsolationTrait())
open class HintsDrivenCatalogContainerInsetTests: BaseTestClass {

    private struct Item: Identifiable {
        let id: String
        let title: String
    }

    private var items: [Item] {
        [
            Item(id: "a", title: "Alpha"),
            Item(id: "b", title: "Beta")
        ]
    }

    @Test @MainActor func catalogListKeepsTheDefaultInset() throws {
        initializeTestConfig()
        let insets = try catalogLeadingInsets(preference: .list, surface: .settings, override: nil)
        #expect(CollectionContentInset.default == 16)
        #expect(insets.contains(CollectionContentInset.default))
    }

    @Test @MainActor func catalogListHonorsANonDefaultInset() throws {
        initializeTestConfig()
        let insets = try catalogLeadingInsets(preference: .list, surface: .settings, override: 24)
        #expect(insets.contains(24))
        #expect(!insets.contains(CollectionContentInset.default))
    }

    @Test @MainActor func catalogListHonorsAZeroInset() throws {
        initializeTestConfig()
        let insets = try catalogLeadingInsets(preference: .list, surface: .settings, override: 0)
        #expect(insets.contains(0))
        #expect(!insets.contains(CollectionContentInset.default))
    }

    @Test @MainActor func catalogGridKeepsTheDefaultInset() throws {
        initializeTestConfig()
        let insets = try catalogLeadingInsets(preference: .grid, surface: .media, override: nil)
        #expect(insets.contains(CollectionContentInset.default))
    }

    @Test @MainActor func catalogGridHonorsANonDefaultInset() throws {
        initializeTestConfig()
        let insets = try catalogLeadingInsets(preference: .grid, surface: .media, override: 24)
        #expect(insets.contains(24))
        #expect(!insets.contains(CollectionContentInset.default))
    }

    @Test @MainActor func catalogGridHonorsAZeroInset() throws {
        initializeTestConfig()
        let insets = try catalogLeadingInsets(preference: .grid, surface: .media, override: 0)
        #expect(insets.contains(0))
        #expect(!insets.contains(CollectionContentInset.default))
    }

    /// Leading insets ViewInspector can read on the catalog stacks.
    /// `.padding(length)` is an all-edge inset, so leading is that length.
    @MainActor
    private func catalogLeadingInsets(
        preference: PresentationPreference,
        surface: HintsDrivenCatalogLayout.Surface,
        override: CGFloat?
    ) throws -> [CGFloat] {
        #if canImport(ViewInspector)
        let catalog = HintsDrivenCatalogContainer(
            items: items,
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: preference,
                complexity: .moderate,
                context: .dashboard
            ),
            surface: surface
        ) { item in
            Text(item.title)
        }
        if let override {
            return try leadingInsets(of: catalog.environment(\.collectionContentInset, override))
        }
        return try leadingInsets(of: catalog)
        #else
        Issue.record("ViewInspector is required to read the catalog inset")
        return []
        #endif
    }

    #if canImport(ViewInspector)
    private func leadingInsets<V: View>(of view: V) throws -> [CGFloat] {
        try view.inspect().findAll { node in
            node.hasPadding(.all) || node.hasPadding(.leading) || node.hasPadding(.horizontal)
        }.compactMap { node in
            try? node.padding(.leading)
        }
    }
    #endif
}
