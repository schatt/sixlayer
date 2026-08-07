import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: Select / radio fields render interactive pickers from DynamicFormField options
 * and bind chosen values through DynamicFormState.
 *
 * TESTING SCOPE: Field wiring, options cardinality, formState round-trip, hostability.
 * Picker chrome / a11y tree interaction → #403 (VI/XCUI).
 *
 * METHODOLOGY: Unit-layer contracts on DynamicSelectField / DynamicRadioField — not type-name
 * theater or ad-hoc Picker trees built only inside the test (#382).
 */
@Suite("Select Field Implementation", HostedViewTestIsolationTrait())
open class SelectFieldImplementationTests: BaseTestClass {

    private var selectField: DynamicFormField {
        DynamicFormField(
            id: "test-select",
            contentType: .select,
            label: "Choose Option",
            placeholder: "Select an option",
            isRequired: true,
            options: ["Option 1", "Option 2", "Option 3", "Option 4"],
            defaultValue: ""
        )
    }

    @MainActor
    private func makeFormState() -> DynamicFormState {
        DynamicFormState(
            configuration: DynamicFormConfiguration(
                id: "test-form",
                title: "Test Form",
                sections: []
            )
        )
    }

    @MainActor
    private func expectHostableRed<V: View>(_ view: V, _ label: String) {
        // Deliberate inverted hostability for #382 red — flip to isHostable for green.
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: \(label) should be hostable"
        )
    }

    // MARK: - DynamicSelectField

    @Test @MainActor func testDynamicSelectFieldWiresFieldAndHosts() {
        initializeTestConfig()
        let field = selectField
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.id == "test-select")
        #expect(sut.field.contentType == .select)
        #expect(sut.field.label == "Choose Option")
        #expect(sut.field.isRequired == true)
        expectHostableRed(sut, "DynamicSelectField")
    }

    @Test @MainActor func testDynamicSelectFieldRetainsOptions() {
        initializeTestConfig()
        let field = selectField
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options == ["Option 1", "Option 2", "Option 3", "Option 4"])
        expectHostableRed(sut, "DynamicSelectField options")
    }

    @Test @MainActor func testDynamicSelectFieldFormStateBinding() {
        initializeTestConfig()
        let field = selectField
        let formState = makeFormState()
        formState.setValue("Option 2", for: field.id)
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(formState.getValue(for: field.id) as String? == "Option 2")
        #expect(sut.field.id == field.id)
        expectHostableRed(sut, "DynamicSelectField binding")
    }

    @Test @MainActor func testDynamicSelectFieldEmptyOptions() {
        initializeTestConfig()
        let field = DynamicFormField(
            id: "empty-select",
            contentType: .select,
            label: "Empty Select",
            placeholder: "No options available",
            options: []
        )
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options?.isEmpty == true)
        expectHostableRed(sut, "DynamicSelectField empty options")
    }

    @Test @MainActor func testDynamicSelectFieldSingleOption() {
        initializeTestConfig()
        let field = DynamicFormField(
            id: "single-select",
            contentType: .select,
            label: "Single Option",
            placeholder: "Only one choice",
            options: ["Only Option"]
        )
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options == ["Only Option"])
        expectHostableRed(sut, "DynamicSelectField single option")
    }

    @Test @MainActor func testDynamicSelectFieldManyOptions() {
        initializeTestConfig()
        let manyOptions = (1...50).map { "Option \($0)" }
        let field = DynamicFormField(
            id: "many-select",
            contentType: .select,
            label: "Many Options",
            placeholder: "Choose from many options",
            options: manyOptions
        )
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options?.count == 50)
        expectHostableRed(sut, "DynamicSelectField many options")
    }

    @Test @MainActor func testDynamicSelectFieldRequiredEmptyValue() {
        initializeTestConfig()
        let field = selectField
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.isRequired == true)
        #expect((formState.getValue(for: field.id) as String? ?? "").isEmpty)
        expectHostableRed(sut, "DynamicSelectField required empty")
    }

    @Test @MainActor func testDynamicSelectFieldAccessibilityWiring() {
        initializeTestConfig()
        // Label/hint tree observation needs VI (#403); unit observes field label + hostability.
        let field = selectField
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.label == "Choose Option")
        expectHostableRed(sut, "DynamicSelectField a11y")
    }

    // MARK: - DynamicRadioField

    @Test @MainActor func testDynamicRadioFieldWiresOptions() {
        initializeTestConfig()
        let field = DynamicFormField(
            id: "radio",
            contentType: .radio,
            label: "Choose Option",
            options: ["Option A", "Option B", "Option C"]
        )
        let formState = makeFormState()
        let sut = DynamicRadioField(field: field, formState: formState)

        #expect(sut.field.contentType == .radio)
        #expect(sut.field.options == ["Option A", "Option B", "Option C"])
        expectHostableRed(sut, "DynamicRadioField")
    }

    @Test @MainActor func testDynamicRadioFieldFormStateBinding() {
        initializeTestConfig()
        let field = DynamicFormField(
            id: "radio",
            contentType: .radio,
            label: "Choose Option",
            options: ["Option A", "Option B", "Option C"]
        )
        let formState = makeFormState()
        formState.setValue("Option B", for: field.id)
        let sut = DynamicRadioField(field: field, formState: formState)

        #expect(formState.getValue(for: field.id) as String? == "Option B")
        expectHostableRed(sut, "DynamicRadioField binding")
    }
}
