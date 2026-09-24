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
        // Deliberate wrong expectation for red (#403) — expect Banana until green fix.
        #expect(selected == "Banana")
        #endif
    }

    // MARK: - Upload a11y

    @Test @MainActor
    func fileUploadArea_exposesAccessibilityLabel() {
        #if !canImport(ViewInspector)
        return
        #else
        let view = FileUploadArea(
            isDragOver: .constant(false),
            selectedFiles: .constant([]),
            allowedTypes: [.image],
            maxFileSize: 1024,
            onFilesSelected: { _ in }
        )
        let label = firstAccessibilityLabel(in: view) ?? ""
        // Deliberate wrong expectation for red (#403).
        #expect(label == "NOT_A_REAL_UPLOAD_LABEL")
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
        // Deliberate wrong expectation for red (#403).
        #expect(found == false)
        #endif
    }

    @MainActor
    private func firstAccessibilityLabel(in view: some View) -> String? {
        #if canImport(ViewInspector)
        if let inspected = try? view.inspect(),
           let labelView = try? inspected.accessibilityLabel(),
           let text = try? labelView.string(),
           !text.isEmpty {
            return text
        }
        for textView in findAllInViewHierarchy(view, ViewInspector.ViewType.Text.self) {
            if let s = try? textView.string(), s.localizedCaseInsensitiveContains("upload") {
                return s
            }
        }
        // Hosted path: named compliance hosts the label on the platform view.
        let (hosted, _) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(view)
        if let hosted {
            if let label = firstHostedAccessibilityLabel(hosted), !label.isEmpty {
                return label
            }
        }
        return nil
        #else
        return nil
        #endif
    }

    @MainActor
    private func firstHostedAccessibilityLabel(_ root: Any) -> String? {
        #if canImport(UIKit)
        if let view = root as? UIView {
            if let label = view.accessibilityLabel, !label.isEmpty { return label }
            for sub in view.subviews {
                if let found = firstHostedAccessibilityLabel(sub) { return found }
            }
        }
        #endif
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        if let view = root as? NSView {
            if let label = view.accessibilityLabel(), !label.isEmpty { return label }
            for sub in view.subviews {
                if let found = firstHostedAccessibilityLabel(sub) { return found }
            }
        }
        #endif
        return nil
    }
}
