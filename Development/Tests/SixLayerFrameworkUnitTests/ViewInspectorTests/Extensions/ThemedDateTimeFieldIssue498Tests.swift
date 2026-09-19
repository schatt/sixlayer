import Testing
import SwiftUI
#if canImport(ViewInspector)
@testable import ViewInspector
#endif
@testable import SixLayerFramework

/// #498 — Theming datetime must use the same stacked compact pickers as `platformDateTimeInput`.
///
/// A single `DatePicker` with `[.date, .hourAndMinute]` is the layout Apple compresses.
/// `ThemedDateTimeField` must host `ViewThatFits`: HStack first, VStack fallback, and
/// separate date-only and time-only pickers.
@Suite("Themed Date Time Field Adaptive Layout", HostedViewTestIsolationTrait())
open class ThemedDateTimeFieldIssue498Tests: BaseTestClass {

    @Test @MainActor func testThemedDateTimeFieldUsesViewThatFitsHStackThenVStack() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let view = makeThemedDateTimeField()
        let fits = findAllInViewHierarchy(view, ViewInspector.ViewType.ViewThatFits.self)
        #expect(
            !fits.isEmpty,
            "ThemedDateTimeField must use ViewThatFits via platformDateTimeInput (#498)"
        )
        guard let viewThatFits = fits.first else { return }

        let hStack = try? viewThatFits.hStack(0)
        #expect(
            hStack != nil,
            "ViewThatFits first child must be HStack (side-by-side when pills fit) (#498)"
        )
        let vStack = try? viewThatFits.vStack(1)
        #expect(
            vStack != nil,
            "ViewThatFits second child must be VStack (date above time when too narrow) (#498)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    @Test @MainActor func testThemedDateTimeFieldHasSeparatePickersNotCombined() {
        initializeTestConfig()
        #if os(tvOS) || os(watchOS)
        return
        #else
        #if canImport(ViewInspector)
        let view = makeThemedDateTimeField()
        let pickers = findAllInViewHierarchy(view, ViewInspector.ViewType.DatePicker.self)
        #expect(
            pickers.count >= 2,
            "Must host separate date and time DatePickers, not one combined control; got \(pickers.count) (#498)"
        )

        let components = pickers.compactMap(datePickerComponents)
        let hasDateOnly = components.contains { $0.contains(.date) && !$0.contains(.hourAndMinute) }
        let hasTimeOnly = components.contains { $0.contains(.hourAndMinute) && !$0.contains(.date) }
        let hasCombined = components.contains { $0.contains(.date) && $0.contains(.hourAndMinute) }

        #expect(hasDateOnly, "Need a date-only picker; components=\(components) (#498)")
        #expect(hasTimeOnly, "Need a time-only picker; components=\(components) (#498)")
        #expect(
            !hasCombined,
            "Combined [.date, .hourAndMinute] picker compresses instead of stacking; components=\(components) (#498)"
        )
        #else
        Issue.record("ViewInspector not available")
        #endif
        #endif
    }

    @MainActor
    private func makeThemedDateTimeField() -> some View {
        ThemedDateTimeField(selection: .constant(Date(timeIntervalSince1970: 1_700_000_000)), label: "When")
            .enableGlobalAutomaticCompliance()
    }

    #if canImport(ViewInspector)
    @MainActor
    private func datePickerComponents(
        _ picker: ViewInspector.InspectableView<ViewInspector.ViewType.DatePicker>
    ) -> DatePickerComponents? {
        firstComponents(in: picker.content.view, depth: 0)
    }

    private func firstComponents(in value: Any, depth: Int) -> DatePickerComponents? {
        guard depth < 8 else { return nil }
        if let components = value as? DatePickerComponents {
            return components
        }
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let components = child.value as? DatePickerComponents {
                return components
            }
            if let nested = firstComponents(in: child.value, depth: depth + 1) {
                return nested
            }
        }
        return nil
    }
    #endif
}
