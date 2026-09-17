//
//  IntelligentFormPackingTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #488: IntelligentFormView packing must use
//  FieldLayout.formPackMaxItemsPerRow instead of hardcoded 4/2/3.
//

import Testing
@testable import SixLayerFramework

@Suite("Intelligent form packing (#488)")
struct IntelligentFormPackingTests {

    @Test func vertical_packsOneFieldPerRow() {
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .vertical) == 1)
    }

    @Test func horizontal_packsTwoFieldsPerRow() {
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .horizontal) == 2)
    }

    @Test func grid_packsThreeFieldsPerRow() {
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .grid) == 3)
    }

    @Test func compactStandardSpaciousAdaptive_packFour() {
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .compact) == 4)
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .standard) == 4)
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .spacious) == 4)
        #expect(IntelligentFormView.packMaxItemsPerRow(for: .adaptive) == 4)
    }
}
