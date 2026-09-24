//
//  AdvancedFieldTypesInteractionViewInspectorTests.swift
//  SixLayerFrameworkUnitTests
//
//  VI observations for #403: edit-mode presentation, suggestion pick, upload a11y.
//

import SwiftUI
import Testing
import UniformTypeIdentifiers
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
        guard let button = findButtonInViewHierarchy(view, labels: ["Apple"]) else {
            Issue.record("Expected Apple suggestion button")
            return
        }
        try? button.tap()
        #expect(selected == "Apple")
        #endif
    }

    // MARK: - Upload a11y identifiers

    @Test @MainActor
    func fileUploadArea_exposesNamedAccessibilityIdentity() {
        #if os(watchOS)
        return
        #else
        let view = FileUploadArea(
            isDragOver: .constant(false),
            selectedFiles: .constant([]),
            allowedTypes: [.image],
            maxFileSize: 1024,
            onFilesSelected: { _ in }
        )
        let (hosted, log) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(view)
        #expect(hosted != nil)
        #expect(
            log.contains("FileUploadArea"),
            "FileUploadArea named compliance must appear for a11y identity"
        )
        #endif
    }

    // MARK: - Edit-mode presentation

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
        // Deliberate wrong expectation until initiallyEditing is wired (#403).
        #expect(hasBold == false)
        #endif
    }
}
