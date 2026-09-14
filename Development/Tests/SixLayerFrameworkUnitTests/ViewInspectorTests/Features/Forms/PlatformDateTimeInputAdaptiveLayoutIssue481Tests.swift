import Testing
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import SixLayerFramework

/// #481 — Compact date+time must stack when the proposed width cannot fit both pills.
///
/// One `DatePicker` with `[.date, .hourAndMinute]` is an Apple HStack that compresses.
/// `platformDateTimeInput` must split into date + time pickers inside `ViewThatFits`:
/// HStack first (side-by-side when they fit), VStack fallback (one above the other).
@Suite("Platform Date Time Input Adaptive Layout", HostedViewTestIsolationTrait())
open class PlatformDateTimeInputAdaptiveLayoutIssue481Tests: BaseTestClass {

    @Test @MainActor func testDynamicDateTimeFieldUsesViewThatFits() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let view = makeDateTimeFieldView()
        let fits = findAllInViewHierarchy(view, ViewInspector.ViewType.ViewThatFits.self)
        #expect(
            !fits.isEmpty,
            "DynamicDateTimeField must use ViewThatFits so date+time can stack when too narrow (#481)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    @Test @MainActor func testViewThatFitsPrefersHStackThenVStackFallback() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let view = makeDateTimeFieldView()
        let fits = findAllInViewHierarchy(view, ViewInspector.ViewType.ViewThatFits.self)
        #expect(!fits.isEmpty, "Need ViewThatFits to assert HStack-then-VStack (#481)")
        guard let viewThatFits = fits.first else { return }

        let hStack = try? viewThatFits.hStack(0)
        #expect(
            hStack != nil,
            "ViewThatFits first child must be HStack (side-by-side when pills fit) (#481)"
        )
        let vStack = try? viewThatFits.vStack(1)
        #expect(
            vStack != nil,
            "ViewThatFits second child must be VStack (date above time when too narrow) (#481)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    @Test @MainActor func testDateAndTimeAreSeparatePickersNotCombined() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let view = makeDateTimeFieldView()
        let pickers = findAllInViewHierarchy(view, ViewInspector.ViewType.DatePicker.self)
        #expect(
            pickers.count >= 2,
            "Must host separate date and time DatePickers, not one combined control; got \(pickers.count) (#481)"
        )

        let descriptions = pickers.map(datePickerComponentsDescription)
        let hasDateOnly = descriptions.contains { $0.contains(".date") && !$0.contains("hourAndMinute") }
        let hasTimeOnly = descriptions.contains { $0.contains("hourAndMinute") && !$0.contains(".date") }
        let hasCombined = descriptions.contains { $0.contains(".date") && $0.contains("hourAndMinute") }

        #expect(hasDateOnly, "Need a date-only picker; components=\(descriptions) (#481)")
        #expect(hasTimeOnly, "Need a time-only picker; components=\(descriptions) (#481)")
        #expect(
            !hasCombined,
            "Combined [.date, .hourAndMinute] picker compresses instead of stacking; components=\(descriptions) (#481)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    @Test @MainActor func testCustomFieldViewDatetimeUsesViewThatFits() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let field = makeField()
        let state = makeFormState(field: field)
        let view = CustomFieldView(field: field, formState: state)
            .enableGlobalAutomaticCompliance()
        let fits = findAllInViewHierarchy(view, ViewInspector.ViewType.ViewThatFits.self)
        #expect(
            !fits.isEmpty,
            "CustomFieldView datetime must use ViewThatFits via platformDateTimeInput (#481)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    // MARK: - Helpers

    @MainActor
    private func makeField() -> DynamicFormField {
        DynamicFormField(
            id: "probe-datetime-481",
            contentType: .datetime,
            label: "Date",
            placeholder: "Select date and time"
        )
    }

    @MainActor
    private func makeFormState(field: DynamicFormField) -> DynamicFormState {
        let configuration = DynamicFormConfiguration(
            id: "issue-481-form",
            title: "Issue 481",
            sections: []
        )
        let state = DynamicFormState(configuration: configuration)
        state.initializeField(field)
        return state
    }

    @MainActor
    private func makeDateTimeFieldView() -> some View {
        let field = makeField()
        let state = makeFormState(field: field)
        return DynamicDateTimeField(field: field, formState: state)
            .enableGlobalAutomaticCompliance()
    }

    #if canImport(ViewInspector)
    @MainActor
    private func datePickerComponentsDescription(
        _ picker: ViewInspector.InspectableView<ViewInspector.ViewType.DatePicker>
    ) -> String {
        let view = picker.content.view
        if let fromMirror = firstComponentsDump(in: view, depth: 0) {
            return fromMirror
        }
        return String(describing: view)
    }

    private func firstComponentsDump(in value: Any, depth: Int) -> String? {
        guard depth < 8 else { return nil }
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let label = child.label?.lowercased(), label.contains("component") {
                return String(describing: child.value)
            }
            if let nested = firstComponentsDump(in: child.value, depth: depth + 1) {
                return nested
            }
        }
        return nil
    }
    #endif
}
