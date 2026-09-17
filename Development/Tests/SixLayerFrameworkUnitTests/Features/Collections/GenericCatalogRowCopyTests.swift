//
//  GenericCatalogRowCopyTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #479: generic catalog L1 views must present items and honor hints
//  via the same list/grid surfaces as the custom counterparts.
//

import Foundation
import Testing
@testable import SixLayerFramework

@Suite("Generic catalog row copy (#479)")
struct GenericCatalogRowCopyTests {

    @Test func media_usesTitleAndURL() {
        let item = GenericMediaItem(title: "Photo", url: "https://example.com/a.jpg")
        let copy = GenericCatalogRowCopy.media(item)
        #expect(copy.title == "Photo")
        #expect(copy.detail == "https://example.com/a.jpg")
    }

    @Test func media_withoutURL_hasNilDetail() {
        let copy = GenericCatalogRowCopy.media(GenericMediaItem(title: "Photo"))
        #expect(copy.title == "Photo")
        #expect(copy.detail == nil)
    }

    @Test func numeric_usesLabelValueUnit() {
        let item = GenericNumericData(value: 32.5, label: "mpg", unit: "mpg")
        let copy = GenericCatalogRowCopy.numeric(item)
        #expect(copy.title == "mpg")
        #expect(copy.detail == "32.5 mpg")
    }

    @Test func numeric_withoutUnit_omitsUnit() {
        let copy = GenericCatalogRowCopy.numeric(GenericNumericData(value: 7, label: "Count"))
        #expect(copy.title == "Count")
        #expect(copy.detail == "7")
    }

    @Test func hierarchical_includesLevel() {
        let copy = GenericCatalogRowCopy.hierarchical(
            GenericHierarchicalItem(title: "Child", level: 2)
        )
        #expect(copy.title == "Child")
        #expect(copy.detail == "Level 2")
    }

    @Test func hierarchical_levelZero_includesLevel() {
        let copy = GenericCatalogRowCopy.hierarchical(
            GenericHierarchicalItem(title: "Root", level: 0)
        )
        #expect(copy.title == "Root")
        #expect(copy.detail == "Level 0")
    }

    @Test func hierarchicalLeadingPadding_zeroLevelIsZero() {
        let item = GenericHierarchicalItem(title: "Root", level: 0)
        #expect(GenericCatalogRowCopy.hierarchicalLeadingPadding(item) == 0)
    }

    @Test func hierarchicalLeadingPadding_scalesWithLevel() {
        let item = GenericHierarchicalItem(title: "Child", level: 2)
        #expect(GenericCatalogRowCopy.hierarchicalLeadingPadding(item) == 24)
    }

    @Test func temporal_usesISODate() {
        let date = Date(timeIntervalSince1970: 0)
        let copy = GenericCatalogRowCopy.temporal(
            GenericTemporalItem(title: "Epoch", date: date)
        )
        #expect(copy.title == "Epoch")
        #expect(copy.detail == "1970-01-01")
    }
}
