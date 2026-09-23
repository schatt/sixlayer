//
//  IntelligentFormViewDebugUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for IntelligentFormView+Debug (#469).
//

import Testing
@testable import SixLayerFramework

@Suite("IntelligentFormView Debug (#469)")
@MainActor
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

        #expect(effective == ["title", "zulu"])
        #expect(warnings.isEmpty)
    }
}
