//
//  IntelligentFormFieldHintsLayoutTests.swift
//  SixLayerFrameworkTests
//
//  IntelligentFormView must pass FieldDisplayHints into every field layout,
//  including `.grid` (GitHub #385).
//

import Testing
@testable import SixLayerFramework

@Suite("Intelligent Form Field Hints Layout")
struct IntelligentFormFieldHintsLayoutTests {

    @Test func fieldHintsForLayout_grid_preservesProvidedHints() {
        let provided: [String: FieldDisplayHints] = [
            "postalCode": FieldDisplayHints(displayWidth: "narrow")
        ]
        let resolved = IntelligentFormView.fieldHintsForLayout(.grid, provided: provided)
        #expect(resolved["postalCode"]?.displayWidth == "narrow")
        #expect(!resolved.isEmpty)
    }

    @Test func fieldHintsForLayout_vertical_preservesProvidedHints() {
        let provided: [String: FieldDisplayHints] = [
            "email": FieldDisplayHints(displayWidth: "wide")
        ]
        let resolved = IntelligentFormView.fieldHintsForLayout(.vertical, provided: provided)
        #expect(resolved["email"]?.displayWidth == "wide")
    }
}
