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
    private func expectHostable<V: View>(_ view: V, _ label: String) {
        #expect(
            PlatformContainerStructureAssertions.isHostable(view),
            "\(label) should be hostable (#382)"
        )
    }

    @MainActor
    private func makeSelectField(
        id: String = "test-select",
        label: String = "Choose Option",
        placeholder: String = "Select an option",
        isRequired: Bool = true,
        options: [String] = ["Option 1", "Option 2", "Option 3", "Option 4"]
    ) -> DynamicFormField {
        DynamicFormField(
            id: id,
            contentType: .select,
            label: label,
            placeholder: placeholder,
            isRequired: isRequired,
            options: options,
            defaultValue: ""
        )
    }

    @MainActor
    private func makeRadioField(
        options: [String] = ["Option A", "Option B", "Option C"]
    ) -> DynamicFormField {
        DynamicFormField(
            id: "radio",
            contentType: .radio,
            label: "Choose Option",
            options: options
        )
    }

    // MARK: - DynamicSelectField

    @Test @MainActor func testDynamicSelectFieldWiresFieldAndHosts() {
        initializeTestConfig()
        let field = makeSelectField()
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.id == "test-select")
        #expect(sut.field.contentType == .select)
        #expect(sut.field.label == "Choose Option")
        #expect(sut.field.isRequired == true)
        expectHostable(sut, "DynamicSelectField")
    }

    @Test @MainActor func testDynamicSelectFieldRetainsOptions() {
        initializeTestConfig()
        let field = makeSelectField()
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options == ["Option 1", "Option 2", "Option 3", "Option 4"])
        expectHostable(sut, "DynamicSelectField options")
    }

    @Test @MainActor func testDynamicSelectFieldFormStateBinding() {
        initializeTestConfig()
        let field = makeSelectField()
        let formState = makeFormState()
        formState.setValue("Option 2", for: field.id)
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(formState.getValue(for: field.id) as String? == "Option 2")
        #expect(sut.field.id == field.id)
        expectHostable(sut, "DynamicSelectField binding")
    }

    @Test @MainActor func testDynamicSelectFieldEmptyOptions() {
        initializeTestConfig()
        let field = makeSelectField(
            id: "empty-select",
            label: "Empty Select",
            placeholder: "No options available",
            isRequired: false,
            options: []
        )
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options?.isEmpty == true)
        expectHostable(sut, "DynamicSelectField empty options")
    }

    @Test @MainActor func testDynamicSelectFieldSingleOption() {
        initializeTestConfig()
        let field = makeSelectField(
            id: "single-select",
            label: "Single Option",
            placeholder: "Only one choice",
            options: ["Only Option"]
        )
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options == ["Only Option"])
        expectHostable(sut, "DynamicSelectField single option")
    }

    @Test @MainActor func testDynamicSelectFieldManyOptions() {
        initializeTestConfig()
        let manyOptions = (1...50).map { "Option \($0)" }
        let field = makeSelectField(
            id: "many-select",
            label: "Many Options",
            placeholder: "Choose from many options",
            options: manyOptions
        )
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.options?.count == 50)
        expectHostable(sut, "DynamicSelectField many options")
    }

    @Test @MainActor func testDynamicSelectFieldRequiredEmptyValue() {
        initializeTestConfig()
        let field = makeSelectField()
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.isRequired == true)
        #expect((formState.getValue(for: field.id) as String? ?? "").isEmpty)
        expectHostable(sut, "DynamicSelectField required empty")
    }

    @Test @MainActor func testDynamicSelectFieldAccessibilityWiring() {
        initializeTestConfig()
        // Label/hint tree observation needs VI (#403); unit observes field label + hostability.
        let field = makeSelectField()
        let formState = makeFormState()
        let sut = DynamicSelectField(field: field, formState: formState)

        #expect(sut.field.label == "Choose Option")
        expectHostable(sut, "DynamicSelectField a11y")
    }

    // MARK: - DynamicRadioField

    @Test @MainActor func testDynamicRadioFieldWiresOptions() {
        initializeTestConfig()
        let field = makeRadioField()
        let formState = makeFormState()
        let sut = DynamicRadioField(field: field, formState: formState)

        #expect(sut.field.contentType == .radio)
        #expect(sut.field.options == ["Option A", "Option B", "Option C"])
        expectHostable(sut, "DynamicRadioField")
    }

    @Test @MainActor func testDynamicRadioFieldFormStateBinding() {
        initializeTestConfig()
        let field = makeRadioField()
        let formState = makeFormState()
        formState.setValue("Option B", for: field.id)
        let sut = DynamicRadioField(field: field, formState: formState)

        #expect(formState.getValue(for: field.id) as String? == "Option B")
        expectHostable(sut, "DynamicRadioField binding")
    }
}
