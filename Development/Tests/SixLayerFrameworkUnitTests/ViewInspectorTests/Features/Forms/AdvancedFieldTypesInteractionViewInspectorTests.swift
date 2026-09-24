//
//  AdvancedFieldTypesInteractionViewInspectorTests.swift
//  SixLayerFrameworkUnitTests
//
//  VI observations for #403 / #524: edit-mode presentation + suggestion pick.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

@Suite("Advanced field types interaction (#403)", HostedViewTestIsolationTrait())
struct AdvancedFieldTypesInteractionViewInspectorTests {

    @MainActor
    private func formState() -> DynamicFormState {
        DynamicFormState(
            configuration: DynamicFormConfiguration(
                id: "advanced-403",
                title: "Advanced 403",
                description: nil,
                sections: [],
                submitButtonText: "Submit",
                cancelButtonText: "Cancel"
            )
        )
    }

    @MainActor
    private func richTextField() -> DynamicFormField {
        DynamicFormField(
            id: "richText",
            contentType: .richtext,
            label: "Rich Text",
            placeholder: "Enter rich text"
        )
    }

    // MARK: - Suggestion pick

    @Test @MainActor
    func autocompleteSuggestions_selectFiresOnSelect() {
        #if !canImport(ViewInspector)
        return
        #else
        var selected: String?
        let view = AutocompleteSuggestions(
            suggestions: ["Apple", "Banana"],
            onSelect: { selected = $0 }
        )
        let button = findButtonInViewHierarchy(view, labels: ["Apple"])
        #expect(button != nil, "Expected Apple suggestion button")
        try? button?.tap()
        #expect(selected == "Apple")
        #endif
    }

    // MARK: - Edit-mode presentation
    // FileUploadArea named compliance: unit lane FileUploadAreaHostUnitTests (#403 / #524).

    @Test @MainActor
    func richTextEditorField_previewModeShowsEditControl() {
        #if !canImport(ViewInspector)
        return
        #else
        let i18n = InternationalizationService()
        let editLabel = i18n.localizedString(for: "SixLayerFramework.button.edit")
        let sut = RichTextEditorField(field: richTextField(), formState: formState())
        let found = findButtonInViewHierarchy(sut, labels: [editLabel, "Edit"]) != nil
        #expect(found, "Preview mode must expose Edit control")
        #endif
    }

    @Test @MainActor
    func richTextEditorField_editingModeShowsToolbarFormatControls() {
        #if !canImport(ViewInspector)
        return
        #else
        let sut = RichTextEditorField(
            field: richTextField(),
            formState: formState(),
            initiallyEditing: true
        )
        let hasBold = findButtonInViewHierarchy(sut, labels: ["B"]) != nil
        #expect(hasBold, "Editing mode must expose toolbar format controls")
        #endif
    }
}
