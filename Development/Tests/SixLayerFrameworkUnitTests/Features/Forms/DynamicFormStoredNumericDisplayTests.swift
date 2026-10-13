import Foundation
import Testing

@testable import SixLayerFramework

@Suite("DynamicFormStoredNumericDisplay")
open class DynamicFormStoredNumericDisplayTests: BaseTestClass {

    @Test func displayString_usesStringAsIs() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: "12.5", defaultValue: "0")
            == "12.5"
        )
    }

    @Test func displayString_formatsDoubleWithoutScientificNotation() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: 12.5, defaultValue: nil)
            == "12.5"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: 42_000.0, defaultValue: nil)
            == "42000"
        )
    }

    @Test func displayString_formatsInt() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: 7, defaultValue: nil)
            == "7"
        )
    }

    @Test func displayString_formatsNSNumber() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: NSNumber(value: 12.5), defaultValue: nil)
            == "12.5"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: NSNumber(value: 9), defaultValue: nil)
            == "9"
        )
    }

    @Test func displayString_fallsBackToDefaultWhenNilOrUnsupported() {
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: nil, defaultValue: "9")
            == "9"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: Date(), defaultValue: "fallback")
            == "fallback"
        )
        #expect(
            DynamicFormStoredNumericDisplay.displayString(fromStoredValue: nil, defaultValue: nil)
            == ""
        )
    }

    @Test @MainActor func formState_doubleValueDisplaysForNumberFieldBinding() {
        let field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons",
            defaultValue: "0"
        )
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        let state = DynamicFormState(configuration: config)
        state.setValue(12.5, for: "gallons")

        let binding = field.numericTextBinding(formState: state)
        #expect(binding.wrappedValue == "12.5")
        #expect(binding.wrappedValue.isEmpty == false)
    }

    @Test @MainActor func formState_intValueDisplaysForIntegerFieldBinding() {
        let field = DynamicFormField(
            id: "odometer",
            contentType: .integer,
            label: "Odometer"
        )
        let config = DynamicFormConfiguration(id: "car", title: "Car", sections: [])
        let state = DynamicFormState(configuration: config)
        state.setValue(12345, for: "odometer")

        let binding = field.numericTextBinding(formState: state)
        #expect(binding.wrappedValue == "12345")
    }

    @Test @MainActor func formState_existingStringValueUnchanged() {
        let field = DynamicFormField(
            id: "gallons",
            contentType: .number,
            label: "Gallons"
        )
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        let state = DynamicFormState(configuration: config)
        state.setValue("12.50", for: "gallons")

        let binding = field.numericTextBinding(formState: state)
        #expect(binding.wrappedValue == "12.50")
    }

    /// A sibling field echoing the string still on screen must not replace a calculated number (#558).
    @Test @MainActor func binding_unfocusedStaleStringDoesNotReplaceStoredDouble() {
        let (field, state) = numberField("fuelCost")
        state.focusedFieldId = "gallons"
        state.setValue(33.24, for: "fuelCost")

        field.numericTextBinding(formState: state).wrappedValue = "21.82"

        #expect(state.getValue(for: "fuelCost") as Double? == 33.24)
    }

    @Test @MainActor func binding_unfocusedEmptyStringDoesNotClearStoredDouble() {
        let (field, state) = numberField("totalCost")
        state.focusedFieldId = "gallons"
        state.setValue(33.24, for: "totalCost")

        field.numericTextBinding(formState: state).wrappedValue = ""

        #expect(state.getValue(for: "totalCost") as Double? == 33.24)
    }

    @Test @MainActor func binding_focusedFieldReplacesStoredDouble() {
        let (field, state) = numberField("fuelCost")
        state.focusedFieldId = "fuelCost"
        state.setValue(33.24, for: "fuelCost")

        field.numericTextBinding(formState: state).wrappedValue = "40"

        #expect(state.getValue(for: "fuelCost") as String? == "40")
    }

    @Test @MainActor func binding_storedStringAcceptsWriteWhenUnfocused() {
        let (field, state) = numberField("gallons")
        state.focusedFieldId = nil
        state.setValue("6.234", for: "gallons")

        field.numericTextBinding(formState: state).wrappedValue = "9.5"

        #expect(state.getValue(for: "gallons") as String? == "9.5")
    }

    @Test @MainActor func binding_sameNumberRefreshesStoredDouble() {
        let (field, state) = numberField("fuelCost")
        state.focusedFieldId = nil
        state.setValue(33.24, for: "fuelCost")

        field.numericTextBinding(formState: state).wrappedValue = "33.24"

        let stored = state.getValue(for: "fuelCost") as Any?
        let asDouble = stored as? Double
        let asString = stored as? String
        #expect(asDouble == 33.24 || asString == "33.24")
    }

    @MainActor
    private func numberField(_ id: String) -> (DynamicFormField, DynamicFormState) {
        let field = DynamicFormField(id: id, contentType: .number, label: id)
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        let state = DynamicFormState(configuration: config)
        return (field, state)
    }
}
