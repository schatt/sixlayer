//
//  IntelligentFormViewOptionalInitialDataHintsTests.swift
//  SixLayerFramework
//
//  generateForm(for:initialData:) must look up hints by the model type, not Optional<T>.
//

import Foundation
import Testing

@testable import SixLayerFramework

/// Model name is the hints-file stem. It must stay free of an Optional wrapper.
private struct OptionalHintsProbe581 {
    var title: String
}

@Suite("Optional initialData hints lookup (#581)")
struct IntelligentFormViewOptionalInitialDataHintsTests {

    @Test @MainActor func typeBasedFormResolvesUnwrappedModelNameAndFields() {
        let item = OptionalHintsProbe581(title: "Edit me")
        let lookup = IntelligentFormView.initialDataFormHintsLookup(
            dataType: OptionalHintsProbe581.self,
            initialData: item
        )

        #expect(lookup.modelName == "OptionalHintsProbe581")
        #expect(lookup.analysis.fields.contains { $0.name == "title" })
    }
}
