//
//  IntelligentFormViewDebugUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for IntelligentFormView+Debug (#469).
//

import Testing
@testable import SixLayerFramework

@Suite("IntelligentFormView Debug (#469)")
struct IntelligentFormViewDebugUnitTests {

    @Test func inspectEffectiveOrder_prefersTitleWithoutExternalRules() {
        IntelligentFormView.orderRulesProvider = nil
        let analysis = DataAnalysisResult(
            fields: [
                DataField(name: "zulu", type: .string),
                DataField(name: "title", type: .string)
            ],
            complexity: .simple,
            patterns: DataPatterns(),
            recommendations: []
        )

        let (effective, warnings) = IntelligentFormView.inspectEffectiveOrder(analysis: analysis)

        // Deliberate red (#469): inverted order until green
        #expect(effective == ["zulu", "title"])
        #expect(warnings.isEmpty)
    }
}
