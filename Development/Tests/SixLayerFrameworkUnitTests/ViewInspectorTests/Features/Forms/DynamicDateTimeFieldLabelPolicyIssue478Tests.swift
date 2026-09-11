import Testing
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import SixLayerFramework

/// #478 — `CustomFieldView` date/time controls must not show a DatePicker title.
/// `DynamicFormFieldView` already draws the field label; a visible title
/// (`placeholderSelectDateTime()` → “Select date and time”) wraps one letter per
/// line in a 320pt iOS wide claim next to compact date/time pills.
///
/// `DynamicFormLabelTests` listed `.datetime` as self-labeling but never inspected
/// the picker title — that is not sufficient.
@Suite("Dynamic Date Time Field Label Policy", HostedViewTestIsolationTrait())
open class DynamicDateTimeFieldLabelPolicyIssue478Tests: BaseTestClass {

    private let sentinelPlaceholder = "ZZZ_DATETIME_TITLE_MUST_BE_HIDDEN"

    @Test @MainActor func testDynamicDateTimeFieldDatePickerTitleIsEmpty() {
        initializeTestConfig()
        assertDatePickerTitleIsEmpty(
            making: { field, state in DynamicDateTimeField(field: field, formState: state) },
            contentType: .datetime,
            componentName: "DynamicDateTimeField"
        )
    }

    @Test @MainActor func testDynamicDateFieldDatePickerTitleIsEmpty() {
        initializeTestConfig()
        assertDatePickerTitleIsEmpty(
            making: { field, state in DynamicDateField(field: field, formState: state) },
            contentType: .date,
            componentName: "DynamicDateField"
        )
    }

    @Test @MainActor func testDynamicTimeFieldDatePickerTitleIsEmpty() {
        initializeTestConfig()
        assertDatePickerTitleIsEmpty(
            making: { field, state in DynamicTimeField(field: field, formState: state) },
            contentType: .time,
            componentName: "DynamicTimeField"
        )
    }

    @Test @MainActor func testCustomFieldViewDatetimeDatePickerTitleIsEmpty() {
        initializeTestConfig()
        assertDatePickerTitleIsEmpty(
            making: { field, state in CustomFieldView(field: field, formState: state) },
            contentType: .datetime,
            componentName: "CustomFieldView datetime"
        )
    }

    @Test @MainActor func testDynamicDateTimeFieldKeepsAccessibilityLabel() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let field = makeField(contentType: .datetime)
        let state = makeFormState(field: field)
        let view = DynamicDateTimeField(field: field, formState: state)
            .enableGlobalAutomaticCompliance()

        let pickers = findAllInViewHierarchy(view, ViewInspector.ViewType.DatePicker.self)
        #expect(!pickers.isEmpty, "DynamicDateTimeField must host a DatePicker so a11y can attach (#478)")

        let labels = pickers.compactMap { picker -> String? in
            (try? picker.accessibilityLabel().string()) ?? nil
        }
        #expect(
            labels.contains { !$0.isEmpty },
            "Hiding the DatePicker title must not drop the accessibility label; got \(labels) (#478)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    // MARK: - Helpers

    private func makeField(contentType: DynamicContentType) -> DynamicFormField {
        DynamicFormField(
            id: "probe-\(contentType.rawValue)",
            contentType: contentType,
            label: "Date",
            placeholder: sentinelPlaceholder
        )
    }

    private func makeFormState(field: DynamicFormField) -> DynamicFormState {
        let configuration = DynamicFormConfiguration(
            id: "issue-478-form",
            title: "Issue 478",
            sections: []
        )
        let state = DynamicFormState(configuration: configuration)
        state.initializeField(field)
        return state
    }

    private func assertDatePickerTitleIsEmpty<V: View>(
        making: (DynamicFormField, DynamicFormState) -> V,
        contentType: DynamicContentType,
        componentName: String
    ) {
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let field = makeField(contentType: contentType)
        let state = makeFormState(field: field)
        let view = making(field, state).enableGlobalAutomaticCompliance()

        let titles = datePickerTitles(in: view)
        #expect(
            !titles.isEmpty,
            "\(componentName) must host a DatePicker (#478)"
        )
        #expect(
            titles.allSatisfy { $0.isEmpty },
            "\(componentName) DatePicker title must be empty (parent draws the label); got \(titles) (#478)"
        )
        #expect(
            !titles.contains(sentinelPlaceholder),
            "\(componentName) must not use the placeholder as a visible DatePicker title (#478)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    #if canImport(ViewInspector)
    private func datePickerTitles<V: View>(in view: V) -> [String] {
        findAllInViewHierarchy(view, ViewInspector.ViewType.DatePicker.self).map { picker in
            if let text = try? picker.labelView().text().string() {
                return text
            }
            if let text = try? picker.labelView().find(ViewInspector.ViewType.Text.self).string() {
                return text
            }
            return ""
        }
    }
    #endif
}
