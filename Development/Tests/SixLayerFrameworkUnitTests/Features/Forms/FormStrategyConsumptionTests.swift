//
//  FormStrategyConsumptionTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #482–#485: FormStrategy packing, validation, L2 layout, and
//  modal/generic forms sharing the same hints-driven strategy.
//

import Testing
@testable import SixLayerFramework

@Suite("Form strategy consumption (#482-485)")
struct FormStrategyConsumptionTests {

    private func hints(
        preference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        custom: [String: String] = [:]
    ) -> PresentationHints {
        PresentationHints(
            dataType: .form,
            presentationPreference: preference,
            complexity: complexity,
            context: .form,
            customPreferences: custom
        )
    }

    private func packMax(
        preference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        fieldCount: Int = 3
    ) -> Int {
        HintsDrivenFormStrategy.strategy(
            hints: hints(preference: preference, complexity: complexity),
            fieldCount: fieldCount
        ).fieldLayout.formPackMaxItemsPerRow
    }

    // MARK: - #485 packing

    @Test func automaticModerate_packsMultipleFieldsPerRow() {
        #expect(packMax() == 4)
    }

    @Test func formPreference_packsOneFieldPerRow() {
        #expect(packMax(preference: .form) == 1)
    }

    @Test func gridPreference_packsThreeFieldsPerRow() {
        #expect(packMax(preference: .grid, fieldCount: 6) == 3)
    }

    @Test func horizontalLayout_packsTwoFieldsPerRow() {
        #expect(FieldLayout.horizontal.formPackMaxItemsPerRow == 2)
    }

    @Test func verticalLayout_packsOneFieldPerRow() {
        #expect(FieldLayout.vertical.formPackMaxItemsPerRow == 1)
    }

    // MARK: - #483 validation

    @Test func immediateAndRealTime_areLiveValidation() {
        #expect(ValidationStrategy.immediate.isLive)
        #expect(ValidationStrategy.realTime.isLive)
    }

    @Test func deferredAndNone_areNotLiveValidation() {
        #expect(!ValidationStrategy.deferred.isLive)
        #expect(!ValidationStrategy.none.isLive)
    }

    @Test func onSubmitAndCustom_areNotLiveValidation() {
        #expect(!ValidationStrategy.onSubmit.isLive)
        #expect(!ValidationStrategy.custom.isLive)
    }

    @Test func simpleFewFields_usesLiveValidation() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(complexity: .simple),
            fieldCount: 2
        )
        #expect(strategy.validation.isLive)
    }

    @Test func liveStrategy_reportsRequiredEmptyField() {
        let field = DynamicFormField(
            id: "name",
            contentType: .text,
            label: "Name",
            isRequired: true
        )
        let message = FormFieldLiveValidation.message(
            field: field,
            value: "",
            strategy: .immediate
        )
        #expect(message == "Name is required")
    }

    @Test func deferredStrategy_doesNotReportRequiredEmptyField() {
        let field = DynamicFormField(
            id: "name",
            contentType: .text,
            label: "Name",
            isRequired: true
        )
        let message = FormFieldLiveValidation.message(
            field: field,
            value: "",
            strategy: .deferred
        )
        #expect(message == nil)
    }

    @Test func liveStrategy_skipsOptionalEmptyField() {
        let field = DynamicFormField(
            id: "note",
            contentType: .text,
            label: "Note",
            isRequired: false
        )
        let message = FormFieldLiveValidation.message(
            field: field,
            value: "",
            strategy: .realTime
        )
        #expect(message == nil)
    }

    @Test func liveStrategy_reportsRequiredEmptyDataField() {
        let field = DataField(name: "email", type: .string, isOptional: false)
        let message = FormFieldLiveValidation.message(
            field: field,
            value: "",
            strategy: .immediate
        )
        #expect(message == "Email is required")
    }

    @Test func deferredStrategy_doesNotReportRequiredEmptyDataField() {
        let field = DataField(name: "email", type: .string, isOptional: false)
        let message = FormFieldLiveValidation.message(
            field: field,
            value: "",
            strategy: .deferred
        )
        #expect(message == nil)
    }

    @Test func liveStrategy_skipsOptionalEmptyDataField() {
        let field = DataField(name: "note", type: .string, isOptional: true)
        let message = FormFieldLiveValidation.message(
            field: field,
            value: "",
            strategy: .realTime
        )
        #expect(message == nil)
    }

    // MARK: - #484 L2 honors preference and complexity

    @Test @MainActor func l2_formPreference_usesStructuredVertical() {
        let decision = determineOptimalFormLayout_L2(hints: hints(preference: .form))
        #expect(decision.preferredContainer == .structured)
        #expect(decision.fieldLayout == .vertical)
        #expect(decision.contentComplexity == .moderate)
    }

    @Test @MainActor func l2_gridPreference_usesGridFieldLayout() {
        let decision = determineOptimalFormLayout_L2(hints: hints(preference: .grid))
        #expect(decision.fieldLayout == .grid)
    }

    @Test @MainActor func l2_honorsHintsComplexityOverFieldCount() {
        let decision = determineOptimalFormLayout_L2(
            hints: hints(
                complexity: .simple,
                custom: ["fieldCount": "12"]
            )
        )
        #expect(decision.contentComplexity == .simple)
    }

    @Test @MainActor func l2_complexPreference_usesFlexibleContainer() {
        let decision = determineOptimalFormLayout_L2(
            hints: hints(complexity: .complex, custom: ["fieldCount": "12"])
        )
        #expect(decision.preferredContainer == .flexible)
        #expect(decision.fieldLayout == .adaptive)
        #expect(decision.contentComplexity == .complex)
    }

    // MARK: - #482 modal preference shares strategy

    @Test func modalPreference_usesSameFormContainerAsFormPreference() {
        let modal = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .modal),
            fieldCount: 3
        )
        let form = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .form),
            fieldCount: 3
        )
        #expect(modal.containerType == form.containerType)
        #expect(modal.fieldLayout == form.fieldLayout)
        #expect(modal.containerType == .form)
    }
}
