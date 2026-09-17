//
//  IntelligentFormPackingTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #488 packing density and #492 packing spacing.
//

import Testing
@testable import SixLayerFramework

@Suite("Intelligent form packing (#488, #492)")
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

    @Test func compact_usesTightSpacing() {
        #expect(IntelligentFormView.packSpacing(for: .compact) == 8)
    }

    @Test func spaciousAndGrid_useWideSpacing() {
        #expect(IntelligentFormView.packSpacing(for: .spacious) == 20)
        #expect(IntelligentFormView.packSpacing(for: .grid) == 20)
    }

    @Test func horizontal_usesMediumSpacing() {
        #expect(IntelligentFormView.packSpacing(for: .horizontal) == 12)
    }

    @Test func verticalStandardAdaptive_useDefaultSpacing() {
        #expect(IntelligentFormView.packSpacing(for: .vertical) == 16)
        #expect(IntelligentFormView.packSpacing(for: .standard) == 16)
        #expect(IntelligentFormView.packSpacing(for: .adaptive) == 16)
    }
}
